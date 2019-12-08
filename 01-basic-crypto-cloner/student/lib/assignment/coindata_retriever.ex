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

  def start_link(args), do:
    GenServer.start_link(__MODULE__, args)

  def retrieve(pid) do
    if Process.alive?(pid) do
      GenServer.cast(pid, :retrieve)
      :succes
    else
      :failure
    end
  end

  def coinpair(pid), do:
    GenServer.call(pid, :coinpair)

  def get_history(pid), do:
    GenServer.call(pid, :history)

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
    Assignment.RateLimiter.i_want_to_retrieve(self())
    {:ok, {coinpair, timeframe, []}}
  end

  @impl true
  def handle_cast(:retrieve, {coinpair, timeframe, data}) do
    url = make_url(coinpair, timeframe)
    Assignment.Logger.log(['Requesting: ', url])
    {:ok, {{'HTTP/1.1', 200, 'OK'}, _headers, body}} =
      :httpc.request(url)
    data = data ++ Jason.decode!(body)
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

end 
