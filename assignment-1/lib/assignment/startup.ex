defmodule Assignment.Startup do
  require IEx

  @all_coinpairs_url 'https://poloniex.com/public?command=returnTicker'
  @from (DateTime.utc_now() |> DateTime.to_unix()) - 60 * 60 * 24 * 7
  @until DateTime.utc_now() |> DateTime.to_unix()

  defstruct from: @from, until: @until, req_per_sec: 5

  def start_link(args \\ []),
    do: {:ok, spawn_link(__MODULE__, :startup, [struct(__MODULE__, args)])}

  def startup(%__MODULE__{} = info) do
    Assignment.Logger.start_link()
    Assignment.ProcessManager.start_link()
    Assignment.RateLimiter.start_link(info.req_per_sec)
    retrieve_coin_pairs() |> start_processes(info)

    keep_running_until_stopped()
  end

  defp retrieve_coin_pairs() do
    {:ok, {{'HTTP/1.1', 200, 'OK'}, _headers, body}} =
      :httpc.request(@all_coinpairs_url)
    Jason.decode!(body) |> Map.keys() |> Enum.map(fn s -> String.to_atom(s) end)
  end

  defp start_processes(pairs, info) when is_list(pairs) do
    Enum.each(pairs,
      fn p ->
        Assignment.ProcessManager.start_coin_retriever({p, {info.from, info.until}})
      end
    )
  end

  defp keep_running_until_stopped() do
    receive do
      :stop -> Process.exit(self(), :normal)
    end
  end
end
