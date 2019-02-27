defmodule Tcp.Server.Handler do
  alias Tcp.Server.Handler
  use GenServer, restart: :temporary
  require Logger

  defstruct model_pid: nil,
            socket: nil

  def start_link([socket, model_pid]) do
    GenServer.start_link(__MODULE__, [socket, model_pid])
  end

  def init([socket, model_pid]) do
    {:ok, %Handler{model_pid: model_pid, socket: socket}}
  end

  def handle_info({:tcp, _socket, data}, state) do
    Logger.debug("(#{__MODULE__}) Received: #{data} ")
    {:noreply, state}
  end

  def handle_info({:tcp_closed, _socket}, state) do
    Logger.debug("(#{__MODULE__}) Socket closed")
    {:stop, :normal, state}
  end

  def handle_info({:tcp_error, socket, reason}, state) do
    Logger.error("(#{__MODULE__})TCP error: #{reason}")
    :gen_tcp.close(socket)
    {:stop, :normal, state}
  end

  def handle_info(:timeout, state) do
    Logger.debug("(#{__MODULE__}) timeout")
    :gen_tcp.close(state.socket)
    {:stop, :normal, state}
  end

  def terminate(:normal, _state), do: nil

  def terminate(reason, state) do
    Logger.error("(#{__MODULE__}) Error: #{inspect(reason)}")
    :gen_tcp.close(state.socket)
  end
end
