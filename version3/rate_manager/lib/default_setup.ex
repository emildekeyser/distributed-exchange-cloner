defmodule RateManager.DefaultSetup do

  defp is_cloner?(node) do
    case :rpc.call(node, :application, :get_key, [:cloner, :modules]) do
      {:ok, list} -> Enum.member?(list, Cloner)
      _ -> false
    end
  end

def make_default_setup() do
  g = :default_group
  RateManager.add_group(g)

  Node.list()
  |> Enum.filter(&is_cloner?/1)
  |> Enum.each(fn n ->
    Process.sleep(1000)
    RateManager.add_node_to_group(n, g)
  end
  )
end

end
