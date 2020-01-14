defmodule Reporter.Application do
  use Application

  def start(_type, _args) do
    Reporter.start_link()
  end

end
