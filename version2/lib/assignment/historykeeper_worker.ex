defmodule Assignment.HistoryKeeperWorker do
  use GenServer

  def start_link(name), do:
    GenServer.start_link(__MODULE__, [], name: name)

  def save(name, timeframe, data), do:
    GenServer.cast(name, {:save, timeframe, data})

  def load(name), do:
    GenServer.call(name, :load)

  def get_history(name), do:
    GenServer.call(name, :load)

  @impl true
  def init(_) do
    {:ok, %{}}
  end

  # TODO?: also persistent (disk) storage ?
  @impl true
  def handle_cast({:save, timeframe, newdata}, data) do
    {:noreply, Map.put(data, timeframe, newdata)}
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
