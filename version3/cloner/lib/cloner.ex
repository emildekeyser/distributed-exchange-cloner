defmodule Cloner do
  use Application

  def start(_type, _args) do

    from = Application.fetch_env!(:cloner, :from)
    until = Application.fetch_env!(:cloner, :until)
    max_requests_per_sec = Application.fetch_env!(:cloner, :rate)

    topologies = [
      libcluster_strat: [
        strategy: Cluster.Strategy.Gossip
      ]
    ]

    children = [
      {Cluster.Supervisor, [topologies, [name: Cloner.ClusterSupervisor]]},
      {
        Registry,
        keys: :unique,
        name: Cloner.CoindataRegistry
      },
      {
        Registry,
        keys: :unique,
        name: Cloner.HistoryKeeperRegistry
      },
      {
        DynamicSupervisor,
        strategy: :one_for_one,
        name: Cloner.CoindataRetrieverSupervisor
      },
      {
        DynamicSupervisor,
        strategy: :one_for_one,
        name: Cloner.HistoryKeeperWorkerSupervisor
      },
      # TODO order matters here, fix
      Cloner.Logger,
      {Cloner.RateLimiter, max_requests_per_sec},
      {Cloner.CoindataCoordinator, {from, until}}
    ]

    # This is retarded
    # Process.send_after(Cloner.CoindataCoordinator, :commence, 4000)

    opts = [strategy: :one_for_one, name: Cloner.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
