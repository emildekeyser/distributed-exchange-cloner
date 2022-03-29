defmodule Cloner.Util do

  defp summarize(coinpair) do
    {_, data} = Cloner.HistoryKeeperWorker.get_history(coinpair)
    length(data)
  end

  def generate_report() do
    Registry.select(Cloner.HistoryKeeperRegistry, [{{:"$1", :"$2", :_}, [], [{{:"$1", :"$2"}}]}])
    |> Enum.map(
      fn {pair, _} -> {pair, summarize(pair)} end
    )
  end


end
