# defmodule Assignment.Startup do
#   require IEx

#   @from (DateTime.utc_now() |> DateTime.to_unix()) - 60 * 60 * 24 * 7
#   @until DateTime.utc_now() |> DateTime.to_unix()
#   @max_requests_per_sec 5
#   @all_coinpairs_url 'https://poloniex.com/public?command=returnTicker'

#   def start_link(_args \\ []),
#     do: {:ok, spawn_link(__MODULE__, :startup, [])}

#   def startup() do
#     # Application.ensure_all_started(:inets)
#     # Application.ensure_all_started(:ssl)
#     Assignment.Logger.start_link()
#     Assignment.ProcessManager.start_link()
#     Assignment.RateLimiter.start_link(@max_requests_per_sec)
#     retrieve_coin_pairs() |> start_processes({@from, @until})

#     keep_running_until_stopped()
#   end

#   defp retrieve_coin_pairs() do
#     {:ok, {{'HTTP/1.1', 200, 'OK'}, _headers, body}} =
#       :httpc.request(:get, {@all_coinpairs_url, []}, [], [])
#     Jason.decode!(body) |> Map.keys()
#   end

#   defp start_processes(pairs, timeframe) when is_list(pairs) do
#     Enum.each(pairs,
#       fn p -> Assignment.ProcessManager.start_coin_retriever(p, timeframe) end)
#   end

#   defp keep_running_until_stopped() do
#     receive do
#       :stop -> Process.exit(self(), :normal)
#     end
#   end
# end
