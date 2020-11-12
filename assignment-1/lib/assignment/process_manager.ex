defmodule Assignment.ProcessManager do
  use DynamicSupervisor

  def start_link() do
    DynamicSupervisor.start_link(__MODULE__, [], name: __MODULE__)
  end

  def start_coin_retriever(args) do
    DynamicSupervisor.start_child(__MODULE__, {Assignment.CoindataRetriever, args})
  end

  defp name_from_pid(pid) do
    Process.info(pid)
    |> List.keyfind(:registered_name, 0)
    |> elem(1)
    |> to_string
    end

  def retrieve_coin_processes() do
    DynamicSupervisor.which_children(__MODULE__)
    |> Enum.map(fn {_, pid, _, _} ->
      {name_from_pid(pid), pid} end
    )
  end

  @impl true
  def init(_args) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end

end
