# TODO: use builtin logger
defmodule Assignment.Logger do
  def log(:debug, _msg), do:
      # IO.inspect(msg)
  def log(:info, _msg), do:
      IO.inspect(msg)
  def log(:warn, _msg), do:
      IO.inspect(msg)
  def log(:error, _msg), do:
      IO.inspect(msg)

  def debug(msg), do:
    log(:debug, msg)
  def info(msg), do:
    log(:info, msg)
  def warn(msg), do:
    log(:warn, msg)
  def error(msg), do:
    log(:error, msg)
end
