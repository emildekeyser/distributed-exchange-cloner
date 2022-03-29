defmodule Cloner.RateLimiter do
  use GenServer

  def start_link(max_requests), do:
    GenServer.start_link(__MODULE__, max_requests, name: __MODULE__)

  def enqueue_request(cmd) do
    GenServer.cast(__MODULE__, {:enqueue, cmd})
  end

  def change_rate_limit(new_max_reqs), do:
    GenServer.cast(__MODULE__, {:new_rate, new_max_reqs})

  defp refresh(), do:
    Process.send_after(__MODULE__, :refresh_requests_left, 1000)

  defp retrieval(), do:
    GenServer.cast(__MODULE__, :retrieval)

  defp perform(reqs, []), do: {reqs, []}
  defp perform(0, q), do: {0, q}
  defp perform(reqs, [head | tail]) do
    {module, function, args} = head
    case apply(module, function, args) do
      :succes -> {reqs - 1, tail}
      :failure -> {reqs, tail}
    end
  end

  @impl true
  def init(max_requests) do
    refresh()
    {:ok, {max_requests, max_requests, []}}
  end

  @impl true
  def handle_cast({:enqueue, cmd}, {max_requests, current_requests, q}) do
    {:noreply, {max_requests, current_requests, q ++ [cmd]}}
  end

  @impl true
  def handle_cast(:retrieval, {max_requests, current_requests, q}) do
    {new_current_request, new_q} = perform(current_requests, q)
    if new_current_request > 0, do: retrieval()
    {:noreply, {max_requests,  new_current_request, new_q}}
  end

  @impl true
  def handle_cast({:new_rate, new_max_reqs}, {_, current_requests, q}), do:
    {:noreply, {new_max_reqs, current_requests, q}}

  @impl true
  def handle_info(:refresh_requests_left, {max_requests, _current_requests, q}) do
    refresh()
    retrieval()
    {:noreply, {max_requests, max_requests, q}}
  end

end
