defmodule Reporter do
  use GenServer

#        ::::::::  :::        ::::::::::: :::::::::: ::::    ::: ::::::::::: 
#      :+:    :+: :+:            :+:     :+:        :+:+:   :+:     :+:      
#     +:+        +:+            +:+     +:+        :+:+:+  +:+     +:+       
#    +#+        +#+            +#+     +#++:++#   +#+ +:+ +#+     +#+        
#   +#+        +#+            +#+     +#+        +#+  +#+#+#     +#+         
#  #+#    #+# #+#            #+#     #+#        #+#   #+#+#     #+#          
#  ########  ########## ########### ########## ###    ####     ###           

  def start_link(args \\ []), do:
    GenServer.start_link(__MODULE__, args, name: __MODULE__)

  def report() do
    Assignment.CoindataCoordinator.retrieve_coin_processes()
    |> Enum.map(&get_stats/1)
    |> Enum.sort(fn m1, m2 -> m1[:PERCENT] >= m2[:PERCENT] end)
    |> Scribe.print(style: Scribe.Style.Pseudo)
  end

  defp get_stats({pair, pid}) do
    {current, max} = Assignment.CoindataRetriever.get_stats(pid)
    percent = case max do
      0 -> 0
      _ -> current/max*100
    end
    %{NODE: "N1", PAIR: pair, CURRENT: current, MAX: max, PERCENT: percent}
  end

#        ::::::::  :::::::::: :::::::::  :::     ::: :::::::::: ::::::::: 
#      :+:    :+: :+:        :+:    :+: :+:     :+: :+:        :+:    :+: 
#     +:+        +:+        +:+    +:+ +:+     +:+ +:+        +:+    +:+  
#    +#++:++#++ +#++:++#   +#++:++#:  +#+     +:+ +#++:++#   +#++:++#:    
#          +#+ +#+        +#+    +#+  +#+   +#+  +#+        +#+    +#+    
#  #+#    #+# #+#        #+#    #+#   #+#+#+#   #+#        #+#    #+#     
#  ########  ########## ###    ###     ###     ########## ###    ###      

  @impl true
  def init(_args) do
    {:ok, [], {:continue, []}}
  end

  @impl true
  def handle_continue(_continue, _state) do
    send(__MODULE__, :report)
    {:noreply, []}
  end

  @impl true
  def handle_info(:report, _state) do
    Reporter.report()
    Process.send_after(__MODULE__, :report, 1000)
    {:noreply, []}
  end

end
