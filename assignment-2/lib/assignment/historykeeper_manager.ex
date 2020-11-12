defmodule Assignment.HistoryKeeperManager  do
  use GenServer

  def start_link(args) do
    GenServer.start_link(__MODULE__, args, name: __MODULE__)
  end

  def save(coinpair, timeframe, data) do
    GenServer.cast(__MODULE__, {:save, coinpair, timeframe, data})
  end

  def load(coinpair) do
    GenServer.call(__MODULE__, {:load, coinpair})
  end

  defp name_from_pid(pid) do
    Process.info(pid)
    |> List.keyfind(:registered_name, 0)
    |> elem(1)
    |> to_string
  end

  def retrieve_history_processes() do
    DynamicSupervisor.which_children(Assignment.HistoryKeeperWorkerSupervisor)
    |> Enum.map(fn {_, pid, _, _} ->
      {name_from_pid(pid), pid} end
    )
  end

  defp start_historykeeper_worker(name) do
    DynamicSupervisor.start_child(
      Assignment.HistoryKeeperWorkerSupervisor,
      {Assignment.HistoryKeeperWorker, name}
    )
  end

  defp mkname(coinpair) do
    (to_string(coinpair) <> "_HISTKEEPER")
    |> String.to_atom()
  end

  defp alive(name) do
    pid = Process.whereis(name) 
    if pid == nil do
      false
    else
      Process.alive?(pid)
    end
  end

  @impl true
  def init(_) do
    {:ok, []}
  end

  @impl true
  def handle_cast({:save, coinpair, timeframe, data}, _) do
    name = mkname(coinpair)
    if not alive(name) do
      start_historykeeper_worker(name)
    end
    Assignment.HistoryKeeperWorker.save(name, timeframe, data)
    {:noreply, []}
  end

  @impl true
  def handle_call({:load, coinpair}, _, _) do
    name = mkname(coinpair)
    data = if alive(name) do
      Assignment.HistoryKeeperWorker.load(name)
    else
      %{}
    end
    {:reply, data, []}
  end

end
