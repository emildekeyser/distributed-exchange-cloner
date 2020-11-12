defmodule RateManager.Application do
  use Application

  def start(_type, _args) do

    topologies = [
      libcluster_strat: [
        strategy: Cluster.Strategy.Gossip
      ]
    ]

    children = [
      {Cluster.Supervisor, [topologies, [name: Cloner.ClusterSupervisor]]},
      RateManager
    ]

    opts = [strategy: :one_for_one, name: Cloner.Supervisor]
    Supervisor.start_link(children, opts)
  end

end
