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

  def get_history(pid), do:
    GenServer.call(pid, :history)

  def save(pid, data), do:
    GenServer.cast(pid, {:save, data})

#        ::::::::  :::::::::: :::::::::  :::     ::: :::::::::: ::::::::: 
#      :+:    :+: :+:        :+:    :+: :+:     :+: :+:        :+:    :+: 
#     +:+        +:+        +:+    +:+ +:+     +:+ +:+        +:+    +:+  
#    +#++:++#++ +#++:++#   +#++:++#:  +#+     +:+ +#++:++#   +#++:++#:    
#          +#+ +#+        +#+    +#+  +#+   +#+  +#+        +#+    +#+    
#  #+#    #+# #+#        #+#    #+#   #+#+#+#   #+#        #+#    #+#     
#  ########  ########## ###    ###     ###     ########## ###    ###      

  @impl true
  def init(coinpair) do
    {:ok, {coinpair, []}}
  end

  # TODO?: make this a map merging algorithm instead of full overwrite ?
  # TODO?: also persistent (disk) storage ?
  @impl true
  def handle_cast({:save, newdata}, {coinpair, _data}) do
    {:noreply, {coinpair, newdata}}
  end

  @impl true
  def handle_call(:coinpair, _from, {coinpair, data}) do
    {:reply, coinpair, {coinpair, data}}
  end

  @impl true
  def handle_call(:history, _from, {coinpair, data}) do
    {:reply, {coinpair, data}, {coinpair, data}}
  end

end 
