defmodule Cloner.Logger do
  use GenServer

  def start_link(args), do:
    GenServer.start_link(__MODULE__, args, name: __MODULE__)

  def log(type, msg) do
    # IO.inspect(msg)
    File.write(inspect(Node.self()) <> inspect(type) <> ".log" , inspect(msg) <> "\n", [:append])
  end

  def warn(msg), do: log(:warn, msg)
  def info(msg), do: log(:info, msg)
  def debug(msg), do: log(:debug, msg)

  def init(init_arg) do
    File.write("info.log", "STARING\n", [:write])
    {:ok, init_arg}
  end
end
