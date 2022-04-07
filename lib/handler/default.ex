defmodule Tcp.Client.Handler.Default do
  use Tcp.Client.Handler

  require Logger

  @impl true
  def init(user_init_state) do
    Logger.debug("(#{__MODULE__}) Start Handler: #{inspect(user_init_state)}")
    user_init_state
  end

  @impl true
  def handle_msg(_socket, data, _state) do
    Logger.debug("(#{__MODULE__}) Received: #{data}")
  end

  @impl true
  def handle_close(_socket, _state) do
    Logger.debug("(#{__MODULE__}) Socket closed")
  end

  @impl true
  def handle_error(socket, reason, _state) do
    Logger.error("(#{__MODULE__}) TCP error: #{reason}")
    :gen_tcp.close(socket)
  end

  @impl true
  def handle_timeout(_state), do: Logger.debug("(#{__MODULE__}) Timeout")
end
