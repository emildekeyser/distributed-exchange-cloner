# TODO: Algorithm to retrieve more then 1000 and to retreive diffrent timeframes
defmodule Assignment.CoindataRetriever do
  use GenServer

  # https://poloniex.com/public?command=returnTradeHistory&currencyPair=USDC_TRX&start=1575113140&end=1575717950
  @url_prefix 'https://poloniex.com/public?command=returnTradeHistory&currencyPair='

  def start_link(args = {coinpair, _total_timeframe}), do:
    GenServer.start_link(__MODULE__, args, name: coinpair)

  def retrieve(coinpair, timeframe) do
    if Process.whereis(coinpair) |> Process.alive?() do
      GenServer.cast(coinpair, {:retrieve, timeframe})
      :succes
    else
      :failure
    end
  end

  def get_history(coinpair), do:
    GenServer.call(coinpair, :history)

  def get_stats(coinpair), do:
    GenServer.call(coinpair, :stats)

  defp make_url(coinpair, {from, until}) do
    f = to_charlist(from)
    u = to_charlist(until)
    c = to_string(coinpair)
    l = [@url_prefix, c, '&start=', f, '&end=', u]
    # Pair=USDC_TRX&start=1575113140&end=1575717950
    # we use charlist because httpc => Erlang/OTP => uses charlists
    List.to_charlist(l)
  end

  defp split_timeframe({from, until}) do
    middle = from + ((until - from) / 2)
    earlier = {from, ceil(middle)}
    later = {floor(middle), until}
    {earlier, later}
  end

  defp enqueue_request(coinpair, timeframe) do
    cmd = {__MODULE__, :retrieve, [coinpair, timeframe]}
    Assignment.RateLimiter.enqueue_request(cmd)
  end

  @impl true
  def init({coinpair, total_timeframe}) do
    # TODO check timeframe properly ie. boolean completion flag
    # data = Assignment.HistoryKeeperManager.load(coinpair, timeframe)
    data = [] # tmp
    if data == [], do: enqueue_request(coinpair, total_timeframe)
    {:ok, {coinpair, total_timeframe, data}}
  end

  @impl true
  def init({coinpair, timeframe, data}) do
    {:ok, {coinpair, timeframe, data}}
  end

  @impl true
  def handle_cast({:retrieve, timeframe}, {coinpair, _total_timeframe, data}) do
    url = make_url(coinpair, timeframe)
    Assignment.Logger.log([:debug, 'Requesting: ', url])
    {:ok, {{'HTTP/1.1', 200, 'OK'}, _headers, body}} = :httpc.request(url)
    new_data = Jason.decode!(body)
    if length(new_data) == 1000 do
      {earlier, later} = split_timeframe(timeframe)
      enqueue_request(coinpair, earlier)
      enqueue_request(coinpair, later)
      {:noreply, {coinpair, timeframe, data}}
    else
      data = data ++ new_data
      # Assignment.HistoryKeeperManager.save(coinpair, timeframe, data)
      {:noreply, {coinpair, timeframe, data}}
    end
  end

  @impl true
  def handle_call(:history, _from, {coinpair, timeframe, data}) do
    {:reply, {coinpair, data}, {coinpair, timeframe, data}}
  end

  # TODO
  @impl true
  def handle_call(:stats, _from, {coinpair, timeframe, data}) do
    {:reply, {length(data), length(data)}, {coinpair, timeframe, data}}
  end
end 
