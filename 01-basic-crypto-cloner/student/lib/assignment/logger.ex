defmodule Assignment.Logger do
  use GenServer

  def start_link(), do:
    GenServer.start_link(__MODULE__, [], name: __MODULE__)

  def init(_), do: {:ok, []}

  def handle_cast(msg, _) do
      # IO.puts(msg)
      {:noreply, []}
  end

  def log(msg) do
    GenServer.cast(__MODULE__, msg)
  end
end
