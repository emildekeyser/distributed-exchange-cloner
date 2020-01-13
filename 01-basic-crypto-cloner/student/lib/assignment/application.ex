defmodule Assignment.Application do
  use Application

  def start(_type, _args) do

    from = Application.fetch_env!(:assignment, :from)
    until = Application.fetch_env!(:assignment, :until)
    max_requests_per_sec = Application.fetch_env!(:assignment, :rate)

    children = [
      # {
      #   Registry,
      #   name: Assignment.Coindata.Registry
      # },
      # {
      #   Registry,
      #   name: Assignment.HistoryKeeper.Registry
      # },
      {
        DynamicSupervisor,
        strategy: :one_for_one,
        name: Assignment.CoindataRetrieverSupervisor
      },
      {
        DynamicSupervisor,
        strategy: :one_for_one,
        name: Assignment.HistoryKeeperWorkerSupervisor
      },
      %{
        id: Assignment.HistoryKeeperManager,
        start: {Assignment.HistoryKeeperManager, :start_link, []}
      },
      %{
        id: Assignment.CoindataCoordinator,
        start: {Assignment.CoindataCoordinator, :start_link, [{from, until}]}
      },
      %{
        id: Assignment.RateLimiter,
        start: {Assignment.RateLimiter, :start_link, [max_requests_per_sec]}
      }
    ]

    opts = [strategy: :one_for_one, name: AssignmentTwo.Supervisor]
    Supervisor.start_link(children, opts)
  end

end
