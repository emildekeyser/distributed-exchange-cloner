defmodule Assignment.ProcessManager  do
  use DynamicSupervisor

  @all_coinpairs_url 'https://poloniex.com/public?command=returnTicker'

#        ::::::::  :::        ::::::::::: :::::::::: ::::    ::: ::::::::::: 
#      :+:    :+: :+:            :+:     :+:        :+:+:   :+:     :+:      
#     +:+        +:+            +:+     +:+        :+:+:+  +:+     +:+       
#    +#+        +#+            +#+     +#++:++#   +#+ +:+ +#+     +#+        
#   +#+        +#+            +#+     +#+        +#+  +#+#+#     +#+         
#  #+#    #+# #+#            #+#     #+#        #+#   #+#+#     #+#          
#  ########  ########## ########### ########## ###    ####     ###           

  def start_link(args) do
    DynamicSupervisor.start_link(__MODULE__, args, name: __MODULE__)
  end

  def start_coin_retriever(coinpair, timeframe) do
    spec = {Assignment.CoindataRetriever, {coinpair, timeframe}}
    DynamicSupervisor.start_child(__MODULE__, spec)
  end

  def retrieve_coin_processes() do
    DynamicSupervisor.which_children(__MODULE__)
    |> Enum.map(fn {_, pid, _, _} ->
      {Assignment.CoindataRetriever.coinpair(pid), pid} end)
  end

  defp start_processes(timeframe) do
    {:ok, {{'HTTP/1.1', 200, 'OK'}, _headers, body}} =
      :httpc.request(@all_coinpairs_url)
    Jason.decode!(body)
    |> Map.keys()
    |> Enum.each(fn p
      -> Assignment.ProcessManager.start_coin_retriever(p, timeframe) end)
    # require IEx; IEx.pry()
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
    Task.start_link(fn -> start_processes(timeframe) end)
    DynamicSupervisor.init(strategy: :one_for_one)
  end

end
