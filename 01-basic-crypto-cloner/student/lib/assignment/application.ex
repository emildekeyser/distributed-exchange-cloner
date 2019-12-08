defmodule Assignment.Application do
  use Application

  @all_coinpairs_url 'https://poloniex.com/public?command=returnTicker'

  def start(_type, _args) do

    from = Application.fetch_env!(:assignment, :from)
    until = Application.fetch_env!(:assignment, :until)
    max_requests_per_sec = Application.fetch_env!(:assignment, :rate)

    children = [
      %{
        id: Assignment.ProcessManager,
        start: {Assignment.ProcessManager, :start_link, []}
      },
      %{
        id: Assignment.RateLimiter,
        start: {Assignment.RateLimiter, :start_link, [max_requests_per_sec]}
      }
    ]

    opts = [strategy: :one_for_one, name: AssignmentTwo.Supervisor]
    pid = Supervisor.start_link(children, opts)

    retrieve_coin_pairs() |> start_processes({from, until})

    pid
  end

  defp retrieve_coin_pairs() do
    {:ok, {{'HTTP/1.1', 200, 'OK'}, _headers, body}} =
      :httpc.request(:get, {@all_coinpairs_url, []}, [], [])
    Jason.decode!(body) |> Map.keys()
  end

  defp start_processes(pairs, timeframe) when is_list(pairs) do
    Enum.each(pairs,
      fn p -> Assignment.ProcessManager.start_coin_retriever(p, timeframe) end)
  end

end
