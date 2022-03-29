defmodule Cloner.CoindataRetriever do
  use GenServer, restart: :transient

  # https://poloniex.com/public?command=returnTradeHistory&currencyPair=USDC_TRX&start=1575113140&end=1575717950
  @url_prefix 'https://poloniex.com/public?command=returnTradeHistory&currencyPair='

  def start_link(args = {coinpair, _total_timeframe}), do:
    GenServer.start_link(__MODULE__, args, name: {:via, Registry, {Cloner.CoindataRegistry, coinpair}})

  def start_link(args = {coinpair, _timeframe, _data}), do:
    GenServer.start_link(__MODULE__, args, name: {:via, Registry, {Cloner.CoindataRegistry, coinpair}})

  def retrieve(coinpair, timeframe) do
    pid = case Registry.lookup(Cloner.CoindataRegistry, coinpair) do
      [{p, :nil}] -> p
      [] -> :nil
    end

    if pid != :nil and Process.alive?(pid) do
      GenServer.cast(pid, {:retrieve, timeframe})
      :succes
    else
      :failure
    end
  end

  def get_history(pid), do:
    GenServer.call(pid, :history)

  def get_stats(pid), do:
    GenServer.call(pid, :stats)

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
    Cloner.RateLimiter.enqueue_request(cmd)
  end

  @impl true
  def init({coinpair, total_timeframe}) do
    case Cloner.HistoryKeeperWorker.get_history(coinpair) do
      {todo_timeframes, data} when todo_timeframes != [] ->
        Enum.each(todo_timeframes, fn tf ->
          enqueue_request(coinpair, tf) end
        )
        {:ok, {coinpair, [todo_timeframes], [], data}}
      {[], data} when data != [] ->
        {:ok, {coinpair, [], [total_timeframe], data}}
      _ ->
        enqueue_request(coinpair, total_timeframe)
        {:ok, {coinpair, [total_timeframe], [], []}}
    end
  end

  @impl true
  def init({coinpair, todo_timeframes, done_timeframes, data}) do
    {:ok, {coinpair, todo_timeframes, done_timeframes, data}}
  end

  @impl true
  def handle_cast({:retrieve, timeframe},
    {coinpair, todo_timeframes, done_timeframes, data}) do

    url = make_url(coinpair, timeframe)

    Cloner.Logger.log(:info, ['Requesting:', coinpair])

    {:ok, {{'HTTP/1.1', 200, 'OK'}, _headers, body}} = :httpc.request(url)
    new_data = Jason.decode!(body)

    check = (is_list(new_data) and length(new_data) == 1000)
    check = check or (is_map(new_data) and Map.has_key?(new_data, "error"))

    if check do
      Cloner.Logger.log(:info, ['Halving timeframe for:', coinpair])
      {earlier, later} = split_timeframe(timeframe)
      enqueue_request(coinpair, earlier)
      enqueue_request(coinpair, later)

      {:noreply, {coinpair, [earlier, later], done_timeframes, data}}
    else
      data = data ++ new_data
      todo_timeframes = todo_timeframes -- [timeframe]
      done_timeframes = done_timeframes ++ [timeframe]
      Cloner.HistoryKeeperWorker.save(coinpair, {todo_timeframes, data})

      {:noreply, {coinpair, todo_timeframes, done_timeframes, data}}
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
