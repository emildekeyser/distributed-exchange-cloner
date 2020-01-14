# TODO: Algorithm to retrieve more then 1000 and to retreive diffrent timeframes
defmodule Assignment.CoindataRetriever do
  use GenServer

  # https://poloniex.com/public?command=returnTradeHistory&currencyPair=USDC_TRX&start=1575113140&end=1575717950
  @url_prefix 'https://poloniex.com/public?command=returnTradeHistory&currencyPair='

#        ::::::::  :::        ::::::::::: :::::::::: ::::    ::: ::::::::::: 
#      :+:    :+: :+:            :+:     :+:        :+:+:   :+:     :+:      
#     +:+        +:+            +:+     +:+        :+:+:+  +:+     +:+       
#    +#+        +#+            +#+     +#++:++#   +#+ +:+ +#+     +#+        
#   +#+        +#+            +#+     +#+        +#+  +#+#+#     +#+         
#  #+#    #+# #+#            #+#     #+#        #+#   #+#+#     #+#          
#  ########  ########## ########### ########## ###    ####     ###           

  def start_link(args = {coinpair, _timeframe}), do:
    GenServer.start_link(__MODULE__, args,
      name: {:via, Registry, {Assignment.CoindataRegistry, coinpair}})

  def retrieve(coinpair) do
    [{pid, :nil}] = Registry.lookup(Assignment.CoindataRegistry, coinpair)
    if Process.alive?(pid) do
      GenServer.cast(pid, :retrieve)
      Assignment.Logger.debug("retrieve succes")
      :succes
    else
      :failure
    end
  end

  def coinpair(pid), do:
    GenServer.call(pid, :coinpair)

  def get_history(pid), do:
    GenServer.call(pid, :history)

  def get_stats(pid), do:
    GenServer.call(pid, :stats)

  defp make_url(coinpair, {f, u}) do
    {from, until} = {to_charlist(f), to_charlist(u)}
    # Pair=USDC_TRX&start=1575113140&end=1575717950
    # we use charlist because httpc => Erlang/OTP => uses charlists
    List.to_charlist([@url_prefix, coinpair, '&start=', from, '&end=', until])
  end

#        ::::::::  :::::::::: :::::::::  :::     ::: :::::::::: ::::::::: 
#      :+:    :+: :+:        :+:    :+: :+:     :+: :+:        :+:    :+: 
#     +:+        +:+        +:+    +:+ +:+     +:+ +:+        +:+    +:+  
#    +#++:++#++ +#++:++#   +#++:++#:  +#+     +:+ +#++:++#   +#++:++#:    
#          +#+ +#+        +#+    +#+  +#+   +#+  +#+        +#+    +#+    
#  #+#    #+# #+#        #+#    #+#   #+#+#+#   #+#        #+#    #+#     
#  ########  ########## ###    ###     ###     ########## ###    ###      

  @impl true
  def init({coinpair, timeframe}) do
    data = Assignment.HistoryKeeperManager.load(coinpair, timeframe)
    # TODO check timeframe
    if data == [], do: Assignment.RateLimiter.i_want_to_retrieve(coinpair)
    Assignment.Logger.log(:debug, data)
    {:ok, {coinpair, timeframe, data}}
  end

  @impl true
  def handle_cast(:retrieve, {coinpair, timeframe, data}) do
    url = make_url(coinpair, timeframe)
    Assignment.Logger.log(:debug, ['Requesting: ', url])
    {:ok, {{'HTTP/1.1', 200, 'OK'}, _headers, body}} =
      :httpc.request(url)
    data = data ++ Jason.decode!(body)
    Assignment.HistoryKeeperManager.save(coinpair, timeframe, data)
    {:noreply, {coinpair, timeframe, data}}
  end

  @impl true
  def handle_call(:coinpair, _from, {coinpair, timeframe, data}) do
    {:reply, coinpair, {coinpair, timeframe, data}}
  end

  @impl true
  def handle_call(:history, _from, {coinpair, timeframe, data}) do
    {:reply, {coinpair, data}, {coinpair, timeframe, data}}
  end

  @impl true
  def handle_call(:stats, _from, {coinpair, timeframe, data}) do
    {:reply, {length(data), length(data)}, {coinpair, timeframe, data}}
  end
end 
