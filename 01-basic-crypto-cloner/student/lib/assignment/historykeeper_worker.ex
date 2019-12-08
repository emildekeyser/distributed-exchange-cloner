defmodule Assignment.HistoryKeeperWorker do
  use GenServer

#        ::::::::  :::        ::::::::::: :::::::::: ::::    ::: ::::::::::: 
#      :+:    :+: :+:            :+:     :+:        :+:+:   :+:     :+:      
#     +:+        +:+            +:+     +:+        :+:+:+  +:+     +:+       
#    +#+        +#+            +#+     +#++:++#   +#+ +:+ +#+     +#+        
#   +#+        +#+            +#+     +#+        +#+  +#+#+#     +#+         
#  #+#    #+# #+#            #+#     #+#        #+#   #+#+#     #+#          
#  ########  ########## ########### ########## ###    ####     ###           

  def start_link(args), do:
    GenServer.start_link(__MODULE__, args)

  def coinpair(pid), do:
    GenServer.call(pid, :coinpair)

  def get_history(pid) do
    GenServer.call(pid, :history)
  end

  def load(pid, timeframe) do
    GenServer.call(pid, :load)
    |> Map.get(timeframe, [])
  end

  def save(pid, timeframe, data), do:
    GenServer.cast(pid, {:save, timeframe, data})

#        ::::::::  :::::::::: :::::::::  :::     ::: :::::::::: ::::::::: 
#      :+:    :+: :+:        :+:    :+: :+:     :+: :+:        :+:    :+: 
#     +:+        +:+        +:+    +:+ +:+     +:+ +:+        +:+    +:+  
#    +#++:++#++ +#++:++#   +#++:++#:  +#+     +:+ +#++:++#   +#++:++#:    
#          +#+ +#+        +#+    +#+  +#+   +#+  +#+        +#+    +#+    
#  #+#    #+# #+#        #+#    #+#   #+#+#+#   #+#        #+#    #+#     
#  ########  ########## ###    ###     ###     ########## ###    ###      

  @impl true
  def init(coinpair) do
    {:ok, {coinpair, %{}}}
  end

  # TODO?: make this a map merging algorithm instead of full overwrite ?
  # TODO?: also persistent (disk) storage ?
  @impl true
  def handle_cast({:save, timeframe, newdata}, {coinpair, datamap}) do
    {:noreply, {coinpair, Map.put(datamap, timeframe, newdata)}}
  end

  @impl true
  def handle_call(:coinpair, _from, {coinpair, datamap}) do
    {:reply, coinpair, {coinpair, datamap}}
  end

  @impl true
  def handle_call(:load, _from, {coinpair, datamap}) do
    {:reply, datamap, {coinpair, datamap}}
  end

  @impl true
  def handle_call(:history, _from, {coinpair, datamap}) do
    first = datamap |> Map.values() |> List.first()
    if first == nil do
      {:reply, {coinpair, []}, {coinpair, datamap}}
    else
      {:reply, {coinpair, first}, {coinpair, datamap}}
    end
  end

end 
