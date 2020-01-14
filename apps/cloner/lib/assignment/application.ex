defmodule Assignment.Application do
  use Application

  def start(_type, _args) do

    from = Application.fetch_env!(:cloner, :from)
    until = Application.fetch_env!(:cloner, :until)
    max_requests_per_sec = Application.fetch_env!(:cloner, :rate)

    # TODO: Clean this up (we can remove a lot of redundant parameters)
    children = [
      {
        Registry,
        keys: :unique,
        name: Assignment.CoindataRegistry
      },
      {
        Registry,
        keys: :unique,
        name: Assignment.HistoryKeeperRegistry
      },
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
    ret = Supervisor.start_link(children, opts)
    Assignment.CoindataCoordinator.balance()
    ret
  end

end
