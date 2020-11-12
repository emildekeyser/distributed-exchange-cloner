defmodule Assignment.Logger do
  use GenServer

  def start_link(), do:
    GenServer.start_link(__MODULE__, [], name: __MODULE__)

  def log([type | msg]), do:
    if type != :debug, do: IO.inspect(msg)

  def init(init_arg) do
    {:ok, init_arg}
  end
end
