defmodule Handler.Mock do
  use Tcp.Client.Handler

  require Logger

  @impl true
  def init(test_pid) do
    send(test_pid, :init)
    test_pid
  end

  @impl true
  def handle_msg(_socket, data, test_pid) do
    send(test_pid, {:handle_msg, data})
    test_pid
  end

  @impl true
  def handle_close(_socket, test_pid) do
    send(test_pid, :handle_close)
    test_pid
  end

  @impl true
  def handle_error(_socket, _reason, test_pid) do
    send(test_pid, :handle_error)
    test_pid
  end

  @impl true
  def handle_timeout(test_pid) do
    send(test_pid, :handle_timeout)
    test_pid
  end
end
