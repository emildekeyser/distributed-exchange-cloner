defmodule Assignment.HistoryKeeperManager  do
  use DynamicSupervisor

  @all_coinpairs_url 'https://poloniex.com/public?command=returnTicker'

#        ::::::::  :::        ::::::::::: :::::::::: ::::    ::: ::::::::::: 
#      :+:    :+: :+:            :+:     :+:        :+:+:   :+:     :+:      
#     +:+        +:+            +:+     +:+        :+:+:+  +:+     +:+       
#    +#+        +#+            +#+     +#++:++#   +#+ +:+ +#+     +#+        
#   +#+        +#+            +#+     +#+        +#+  +#+#+#     +#+         
#  #+#    #+# #+#            #+#     #+#        #+#   #+#+#     #+#          
#  ########  ########## ########### ########## ###    ####     ###           

  def start_link() do
    DynamicSupervisor.start_link(__MODULE__, [], name: __MODULE__)
  end

  def save(coinpair, timeframe, data) do
    retrieve_history_processes()
    |> Enum.filter(fn {pair, _pid} -> pair == coinpair end)
    |> List.first()
    |> elem(1)
    |> Assignment.HistoryKeeperWorker.save(timeframe, data)
  end

  def load(coinpair, timeframe) do
    retrieve_history_processes()
    |> Enum.filter(fn {pair, _pid} -> pair == coinpair end)
    |> List.first()
    |> elem(1)
    |> Assignment.HistoryKeeperWorker.load(timeframe)
  end

  def start_historykeeper_worker(coinpair) do
    spec = {Assignment.HistoryKeeperWorker, coinpair}
    DynamicSupervisor.start_child(__MODULE__, spec)
  end

  def retrieve_history_processes() do
    DynamicSupervisor.which_children(__MODULE__)
    |> Enum.map(fn {_, pid, _, _} ->
      {Assignment.HistoryKeeperWorker.coinpair(pid), pid} end)
  end

  defp start_processes() do
    {:ok, {{'HTTP/1.1', 200, 'OK'}, _headers, body}} =
      :httpc.request(@all_coinpairs_url)
    Jason.decode!(body)
    |> Map.keys()
    |> Enum.each(fn p
      -> Assignment.HistoryKeeperManager.start_historykeeper_worker(p) end)
  end

#        ::::::::  :::::::::: :::::::::  :::     ::: :::::::::: ::::::::: 
#      :+:    :+: :+:        :+:    :+: :+:     :+: :+:        :+:    :+: 
#     +:+        +:+        +:+    +:+ +:+     +:+ +:+        +:+    +:+  
#    +#++:++#++ +#++:++#   +#++:++#:  +#+     +:+ +#++:++#   +#++:++#:    
#          +#+ +#+        +#+    +#+  +#+   +#+  +#+        +#+    +#+    
#  #+#    #+# #+#        #+#    #+#   #+#+#+#   #+#        #+#    #+#     
#  ########  ########## ###    ###     ###     ########## ###    ###      

  @impl true
  def init(_) do
    Task.start(&start_processes/0)
    DynamicSupervisor.init(strategy: :one_for_one)
  end

end
