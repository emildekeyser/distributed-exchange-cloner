defmodule Assignment do

  def start(_type, _args) do
    Assignment.Startup.start_link()
  end

end
