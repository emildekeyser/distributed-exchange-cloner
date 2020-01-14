defmodule Assignment.CoindataCoordinator do
  use GenServer

  @all_coinpairs_url 'https://poloniex.com/public?command=returnTicker'

#        ::::::::  :::        ::::::::::: :::::::::: ::::    ::: ::::::::::: 
#      :+:    :+: :+:            :+:     :+:        :+:+:   :+:     :+:      
#     +:+        +:+            +:+     +:+        :+:+:+  +:+     +:+       
#    +#+        +#+            +#+     +#++:++#   +#+ +:+ +#+     +#+        
#   +#+        +#+            +#+     +#+        +#+  +#+#+#     +#+         
#  #+#    #+# #+#            #+#     #+#        #+#   #+#+#     #+#          
#  ########  ########## ########### ########## ###    ####     ###           

  def start_link(timeframe) do
    GenServer.start_link(__MODULE__, timeframe, name: __MODULE__)
  end

  def balance() do
    GenServer.cast(__MODULE__, :balance)
  end

  def retrieve_coin_processes() do
    p = Process.whereis(Assignment.CoindataRegistry)
    if is_pid(p) and Process.alive?(p) do
      Registry.select(Assignment.CoindataRegistry,
        [{{:"$1", :"$2", :_}, [], [{{:"$1", :"$2"}}]}])
    else
      []
    end
  end

  def start_coin_retriever(coinpair, timeframe) do
    spec = {Assignment.CoindataRetriever, {coinpair, timeframe}}
    DynamicSupervisor.start_child(Assignment.CoindataRetrieverSupervisor, spec)
  end

  def get_coinpairs() do
    {:ok, {{'HTTP/1.1', 200, 'OK'}, _headers, body}} =
      :httpc.request(@all_coinpairs_url)
    Jason.decode!(body) |> Map.keys()
  end

  def all_coinpairs_up(timeframe) do
    Assignment.CoindataCoordinator.get_coinpairs()
    |> Enum.each(fn p
      -> Assignment.CoindataCoordinator.start_coin_retriever(p, timeframe) end)
  end

#        ::::::::  :::::::::: :::::::::  :::     ::: :::::::::: ::::::::: 
#      :+:    :+: :+:        :+:    :+: :+:     :+: :+:        :+:    :+: 
#     +:+        +:+        +:+    +:+ +:+     +:+ +:+        +:+    +:+  
#    +#++:++#++ +#++:++#   +#++:++#:  +#+     +:+ +#++:++#   +#++:++#:    
#          +#+ +#+        +#+    +#+  +#+   +#+  +#+        +#+    +#+    
#  #+#    #+# #+#        #+#    #+#   #+#+#+#   #+#        #+#    #+#     
#  ########  ########## ###    ###     ###     ########## ###    ###      

  @impl true
  def init(timeframe) do
    # Assignment.CoindataCoordinator.all_coinpairs_up(timeframe)
    {:ok, timeframe}
  end

  @impl true
  def handle_cast(:balance, timeframe) do
    Assignment.CoindataCoordinator.all_coinpairs_up(timeframe)
    {:noreply, timeframe}
  end

end
