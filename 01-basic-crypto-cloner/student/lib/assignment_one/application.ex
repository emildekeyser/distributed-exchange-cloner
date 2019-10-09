defmodule AssignmentOne.Application do
  use Application

  def start(_type, _args) do
    children = [
      # Do not change this file!
      %{
        id: AssignmentOne.Startup,
        start: {AssignmentOne.Startup, :start_link, []}
      }
    ]

    opts = [strategy: :one_for_one, name: AssignmentOne.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
