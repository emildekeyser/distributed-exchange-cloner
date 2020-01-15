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

  def retrieve_remote_coin_processes(node) do
    GenServer.call({__MODULE__, node}, :retriever_list)
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

  def start_coin_retriever(args) do
    spec = {Assignment.CoindataRetriever, args}
    DynamicSupervisor.start_child(Assignment.CoindataRetrieverSupervisor, spec)
  end

  def get_coinpairs() do
    {:ok, {{'HTTP/1.1', 200, 'OK'}, _headers, body}} =
      :httpc.request(@all_coinpairs_url)
    Jason.decode!(body) |> Map.keys()
  end

  def start_all_coinpairs(timeframe) do
    Assignment.CoindataCoordinator.get_coinpairs()
    |> Enum.each(fn p
      -> Assignment.CoindataCoordinator.start_coin_retriever({p, timeframe}) end)
  end

  defp run_balancing_algo() do
    min = min_pairs_per_node()
    nodemap = map_nodes()
    {rich, poor} = stratify(nodemap, min)
    all_rich_surplus = rich_surplus(rich, nodemap, min)
    transfers = robin_hood(poor, all_rich_surplus)
    perform_transfers(transfers)
  end

  defp min_pairs_per_node() do
    div(length(__MODULE__.get_coinpairs()), length(Node.list())+1)
  end

  defp map_nodes() do
    Map.new(Node.list(), fn n ->
      {n, __MODULE__.retrieve_remote_coin_processes(n)}
    end)
    |> Map.put(Node.self(), __MODULE__.retrieve_coin_processes())
  end

  defp stratify(nodemap, min) do
    poor = Enum.filter(nodemap, fn {_n, pairs} -> length(pairs) < min end)
           |> Map.new() |> Map.keys()
    rich = Map.keys(nodemap) -- poor
    {rich, poor}
  end

  defp rich_surplus(rich, nodemap, min) do
    Map.take(nodemap, rich)
    |> Enum.map(fn {k, v} -> {k, Enum.split(v, min) |> elem(1)} end)
  end

  defp robin_hood(poor, all_rich_surplus) do
    chunksize = ceil(length(all_rich_surplus) / length(poor))
    chunks = Enum.chunk_every(all_rich_surplus, chunksize)
    Enum.zip(poor, chunks)
  end

  defp perform_transfers(transfers) do
    IO.inspect(transfers)
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
    no_retrievers = __MODULE__.retrieve_coin_processes() |> length() == 0
    no_nodes = Node.list() == []
    if no_retrievers and no_nodes do
      __MODULE__.start_all_coinpairs(timeframe)
    else
      run_balancing_algo()
    end
    {:noreply, timeframe}
  end

  @impl true
  def handle_call(:retriever_list, _from, state) do
    {:reply, __MODULE__.retrieve_coin_processes(), state}
  end

end
