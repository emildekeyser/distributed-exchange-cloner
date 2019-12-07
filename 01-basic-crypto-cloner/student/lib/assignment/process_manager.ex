defmodule Assignment.ProcessManager  do
  use DynamicSupervisor

  def start_link() do
    DynamicSupervisor.start_link(__MODULE__, [], name: __MODULE__)
  end

  @impl true
  def init(_) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  def start_coin_retriever(coinpair, timeframe) do
    spec = {Assignment.CoindataRetriever, {coinpair, timeframe}}
    DynamicSupervisor.start_child(__MODULE__, spec)
  end

  def retrieve_coin_processes() do
    DynamicSupervisor.which_children(__MODULE__)
    |> Enum.map(fn {_, pid, _, _} ->
      {Assignment.CoindataRetriever.coinpair(pid), pid} end)
  end

end
