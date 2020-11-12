defmodule Cloner.Balancer do

  # BTC_SNT == tester

  def kill(registry, coinpair), do: 
    GenServer.stop({:via, Registry, {registry, coinpair}})

  def transfer_history_from(node, coinpair) do
    state = :rpc.call(node, Cloner.HistoryKeeperWorker, :get_history, [coinpair])
    Cloner.HistoryKeeperWorker.save(coinpair, state)
    :rpc.call(node, Cloner.Balancer, :kill,
      [Cloner.HistoryKeeperRegistry, coinpair])
  end

  def transfer_worker_from(node, coinpair) do
    :rpc.call(node, Cloner.Balancer, :kill,
      [Cloner.CoindataRegistry, coinpair])
    tf = Cloner.CoindataCoordinator.get_timeframe()
    Cloner.CoindataCoordinator.start_retriever(coinpair, tf)
  end

  def balance(from_nodes) do
    Cloner.Logger.info(["Balancing from:", from_nodes])

    {big_boy, hes_coins} = Enum.map(from_nodes, fn node ->
      {
        node,
        :rpc.call(node, Cloner.CoindataCoordinator, :retrieve_coin_processes, [])
      }
    end)
    |> Enum.sort(fn {_, a}, {_, b} -> length(a) > length(b) end)
    |> List.first()

    Enum.take_random(hes_coins, floor(length(hes_coins) / 2))
    |> Enum.each(fn {coinpair, _pid} ->
      transfer_history_from(big_boy, coinpair)
      transfer_worker_from(big_boy, coinpair)
    end)
  end

end
