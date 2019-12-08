defmodule Assignment.RateLimiter do
  use GenServer

#        ::::::::  :::        ::::::::::: :::::::::: ::::    ::: ::::::::::: 
#      :+:    :+: :+:            :+:     :+:        :+:+:   :+:     :+:      
#     +:+        +:+            +:+     +:+        :+:+:+  +:+     +:+       
#    +#+        +#+            +#+     +#++:++#   +#+ +:+ +#+     +#+        
#   +#+        +#+            +#+     +#+        +#+  +#+#+#     +#+         
#  #+#    #+# #+#            #+#     #+#        #+#   #+#+#     #+#          
#  ########  ########## ########### ########## ###    ####     ###           

  def start_link(max_requests), do:
    GenServer.start_link(__MODULE__, max_requests, name: __MODULE__)

  def i_want_to_retrieve(retriever_id), do:
    GenServer.cast(__MODULE__, {:register, retriever_id})

  def change_rate_limit(new_max_reqs), do:
    GenServer.cast(__MODULE__, {:new_rate, new_max_reqs})

  defp refresh(), do:
    Process.send_after(__MODULE__, :refresh_requests_left, 1000)

  defp retrieval(), do:
    GenServer.cast(__MODULE__, :retrieval)

  defp perform(reqs, []), do: {reqs, []}
  defp perform(0, q), do: {0, q}
  defp perform(reqs, [head | tail]) do
    case Assignment.CoindataRetriever.retrieve(head) do
      :succes -> {reqs - 1, tail}
      :failure -> {reqs, tail}
    end
  end

#        ::::::::  :::::::::: :::::::::  :::     ::: :::::::::: ::::::::: 
#      :+:    :+: :+:        :+:    :+: :+:     :+: :+:        :+:    :+: 
#     +:+        +:+        +:+    +:+ +:+     +:+ +:+        +:+    +:+  
#    +#++:++#++ +#++:++#   +#++:++#:  +#+     +:+ +#++:++#   +#++:++#:    
#          +#+ +#+        +#+    +#+  +#+   +#+  +#+        +#+    +#+    
#  #+#    #+# #+#        #+#    #+#   #+#+#+#   #+#        #+#    #+#     
#  ########  ########## ###    ###     ###     ########## ###    ###      

  @impl true
  def init(max_requests) do
    refresh()
    retrieval()
    {:ok, {max_requests, max_requests, []}}
  end

  @impl true
  def handle_cast({:register, retriever_id}, {max_requests, current_requests, q}) do
    {:noreply, {max_requests, current_requests, q ++ [retriever_id]}}
  end

  @impl true
  def handle_cast(:retrieval, {max_requests, current_requests, q}) do
    {new_current_request, new_q} = perform(current_requests, q)
    retrieval()
    {:noreply, {max_requests,  new_current_request, new_q}}
  end

  @impl true
  def handle_cast({:new_rate, new_max_reqs}, {_, current_requests, q}), do:
    {:noreply, {new_max_reqs, current_requests, q}}

  @impl true
  def handle_info(:refresh_requests_left, {max_requests, _current_requests, q}) do
    Assignment.Logger.log(:info, "--- refresh")
    refresh()
    {:noreply, {max_requests, max_requests, q}}
  end

end
