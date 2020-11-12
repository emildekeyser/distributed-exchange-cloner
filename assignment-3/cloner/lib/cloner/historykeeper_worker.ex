defmodule Cloner.HistoryKeeperWorker do
  use GenServer, restart: :transient

  def start_link(coinpair), do:
  GenServer.start_link(__MODULE__, [],
    name: {:via, Registry, {Cloner.HistoryKeeperRegistry, coinpair}})

  def save(coinpair, data) do
    if Registry.lookup(Cloner.HistoryKeeperRegistry, coinpair) == [] do
      DynamicSupervisor.start_child(Cloner.HistoryKeeperWorkerSupervisor,
        {Cloner.HistoryKeeperWorker, coinpair})
    end

    case Registry.lookup(Cloner.HistoryKeeperRegistry, coinpair) do
      [{pid, :nil}] -> GenServer.cast(pid, {:save, data})
      [] -> :failure
    end
  end

  def get_history(coinpair) do
    case Registry.lookup(Cloner.HistoryKeeperRegistry, coinpair) do
      [{pid, :nil}] -> GenServer.call(pid, :load)
      [] -> {[], []}
    end
  end

  @impl true
  def init(_) do
    {:ok, {[], []}}
  end

  # TODO?: also persistent (disk) storage ?
  @impl true
  def handle_cast({:save, {new_timeframes, new_data}}, _) do
    {:noreply, {new_timeframes, new_data}}
  end

  @impl true
  def handle_call(:load, _from, data) do
    {:reply, data, data}
  end

  # @impl true
  # def handle_call(:coinpair, _from, {coinpair, datamap}) do
  #   {:reply, coinpair, {coinpair, datamap}}
  # end

end 
