defmodule RateManager do
  use GenServer

  def start_link(args \\ []), do: GenServer.start_link(__MODULE__, args, name: __MODULE__)

  def add_group(name, rate \\ 4), do: GenServer.cast(__MODULE__, {:add_group, name, rate})

  def add_node_to_group(node, group),
    do: GenServer.cast(__MODULE__, {:node_to_group, node, group})

  def set_rate(group, rate), do: GenServer.cast(__MODULE__, {:set_rate, group, rate})

  def list_groups(), do: GenServer.call(__MODULE__, :list)

# ------------------------------------------------------------------------------

  defp balance_rate(group) when is_map(group) do
    balance_rate(group[:rate], group[:nodes])
  end

  defp balance_rate(rate, nodes) when rate / length(nodes) > 1 do
    std_rate = floor(rate / length(nodes))
    big_boy = std_rate + rem(rate, length(nodes))
    Enum.each(nodes, fn n ->
      :rpc.call(n, Cloner.RateLimiter, :change_rate_limit, [std_rate]) end
    )
    Enum.random(nodes)
    |> :rpc.call(Cloner.RateLimiter, :change_rate_limit, [big_boy])
  end

  defp balance_workers(from_nodes, to_node) when from_nodes == [] do
    :rpc.call(to_node, Cloner.CoindataCoordinator, :start_cloning, [])
  end

  defp balance_workers(from_nodes, to_node) when length(from_nodes) >= 1 do
    :rpc.call(to_node, Cloner.Balancer, :balance, [from_nodes])
  end

# ------------------------------------------------------------------------------

  @impl true
  def init(_args) do
    {:ok, %{}}
  end

  @impl true
  def handle_cast({:add_group, name, rate}, groups) do
    groups = Map.put(groups, name, %{:nodes => [], :rate => rate})
    {:noreply, groups}
  end

  @impl true
  def handle_cast({:node_to_group, node, group}, groups) do
    nodes = (Map.get(groups, group) |> Map.get(:nodes)) ++ [node]
    group_map = Map.get(groups, group) |> Map.put(:nodes, nodes)
    groups = Map.put(groups, group, group_map)
    balance_rate(group_map)
    balance_workers(nodes -- [node], node)
    {:noreply, groups}
  end

  @impl true
  def handle_cast({:set_rate, group, rate}, groups) do
    group_map = Map.get(groups, group) |> Map.put(:rate, rate)
    groups = Map.put(groups, group, group_map)
    balance_rate(groups[group])
    {:noreply, groups}
  end

  @impl true
  def handle_call(:list, _from, groups) do
    {:reply, groups, groups}
  end
end 
