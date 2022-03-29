defmodule Assignment.ProcessManager do
  use GenServer

  @all_coinpairs_url 'https://poloniex.com/public?command=returnTicker'

  def start_link(args) do
    GenServer.start_link(__MODULE__, args, name: __MODULE__)
  end

  defp name_from_pid(pid) do
    Process.info(pid)
    |> List.keyfind(:registered_name, 0)
    |> elem(1)
    |> to_string
  end

  def retrieve_coin_processes() do
    DynamicSupervisor.which_children(Assignment.CoindataRetrieverSupervisor)
    |> Enum.map(fn {_, pid, _, _} ->
      {name_from_pid(pid), pid} end
    )
  end

  defp retrieve_coin_pairs() do
    {:ok, {{'HTTP/1.1', 200, 'OK'}, _headers, body}} =
      :httpc.request(@all_coinpairs_url)
    Jason.decode!(body) |> Map.keys() |> Enum.map(fn s -> String.to_atom(s) end)
  end

  defp start_retriever(pair, from, until) do
    args = {pair, {from, until}}
    DynamicSupervisor.start_child(
      Assignment.CoindataRetrieverSupervisor,
      {Assignment.CoindataRetriever, args}
    )
  end

  @impl true
  def init({from, until}) do
    retrieve_coin_pairs()
    |> Enum.each(fn p -> start_retriever(p, from, until) end)
    {:ok, {from, until}}
  end

end
