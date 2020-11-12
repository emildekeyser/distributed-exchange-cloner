defmodule Cloner.CoindataCoordinator do
  use GenServer

  @all_coinpairs_url 'https://poloniex.com/public?command=returnTicker'

  def start_link(args) do
    GenServer.start_link(__MODULE__, args, name: __MODULE__)
  end

  def retrieve_coin_processes() do
    Registry.select(Cloner.CoindataRegistry,
      [{{:"$1", :"$2", :_}, [], [{{:"$1", :"$2"}}]}])
  end

  def start_retriever(coinpair, timeframe) do
    DynamicSupervisor.start_child(
      Cloner.CoindataRetrieverSupervisor,
      {Cloner.CoindataRetriever, {coinpair, timeframe}}
    )
  end

  def get_timeframe() do
    GenServer.call(__MODULE__, :timeframe)
  end

  def start_cloning() do
    # No cast to enable send_after in another place
    Cloner.Logger.info("RECEIVED START CMD")
    Process.send(__MODULE__, :start_cloning, [])
  end


# ------------------------------------------------------------------------------

  defp retrieve_coin_pairs() do
    {:ok, {{'HTTP/1.1', 200, 'OK'}, _headers, body}} =
      :httpc.request(@all_coinpairs_url)
    Jason.decode!(body) |> Map.keys() |> Enum.map(fn s -> String.to_atom(s) end)
  end


  # defp allowed_to_commence?() do
  #   # TODO make better (use rpc + function_exported instead of name)
  #   Node.list()
  #   |> Enum.filter(
  #     fn n -> to_string(n) |> String.split("@") |> List.first != "reporter" end
  #   )
  #   |> length() == 0
  # end

# ------------------------------------------------------------------------------
  
  @impl true
  def init(timeframe) do
    {:ok, timeframe}
  end

  @impl true
  def handle_info(:start_cloning, timeframe) do
    Cloner.Logger.info(["Name:", Node.self()])
    Cloner.Logger.info(["Brothers:", Node.list()])
    # if allowed_to_commence?() do
    retrieve_coin_pairs()
    |> Enum.each(fn p -> start_retriever(p, timeframe) end)
    # end
    {:noreply, timeframe}
  end

  @impl true
  def handle_call(:timeframe, _from, timeframe) do
    {:reply, timeframe, timeframe}
  end

end
