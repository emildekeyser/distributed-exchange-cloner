defmodule Assignment do
  use Application

  def start(_type, _args) do

    from = Application.fetch_env!(:assignment, :from)
    until = Application.fetch_env!(:assignment, :until)
    max_requests_per_sec = Application.fetch_env!(:assignment, :rate)

    children = [
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
      # TODO order matters here, fix
      Assignment.Logger,
      Assignment.HistoryKeeperManager,
      {Assignment.RateLimiter, max_requests_per_sec},
      {Assignment.ProcessManager, {from, until}}
    ]

    opts = [strategy: :one_for_one, name: Assignment.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
