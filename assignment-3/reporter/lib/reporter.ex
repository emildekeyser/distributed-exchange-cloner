defmodule Reporter do
  use GenServer

  def start_link(args \\ []), do:
    GenServer.start_link(__MODULE__, args, name: __MODULE__)

  @impl true
  def init(_args) do
    {:ok, []}
  end

  defp is_cloner?(node) do
    case :rpc.call(node, :application, :get_key, [:cloner, :modules]) do
      {:ok, list} -> Enum.member?(list, Cloner)
      _ -> false
    end
  end


  def report() do
    Node.list()
    |> Enum.filter(&is_cloner?/1)
    |> Enum.map(fn n ->
      :rpc.call(n, Cloner.Util, :generate_report, [])
      |> Enum.map(fn {v1, v2} -> {n, v1, v2} end)
    end)
    |> List.flatten()
    |> Enum.sort(fn {_, _, v1}, {_, _, v2} -> v1 > v2 end)
    |> Enum.map(fn {node, pair, value} ->
      %{NODE: node, PAIR: pair, TRADES: value} end
    )
    |> Scribe.print(style: Scribe.Style.Pseudo)
  end

  def always_report(), do:
    Process.send_after(__MODULE__, :report, 5000)

  @impl true
  def handle_info(:report, _state) do
    # clear
    Reporter.report()
    Process.send_after(__MODULE__, :report, 5000)
    {:noreply, []}
  end

end
