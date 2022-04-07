defmodule Tcp.Server do
  alias Tcp.Server
  use GenServer, restart: :temporary
  require Logger

  @port 502
  @to :infinity

  defstruct ip: nil,
            handler_module: nil,
            handler_args: nil,
            tcp_port: nil,
            timeout: nil,
            listener: nil,
            sup_pid: nil,
            acceptor_pid: nil

  def start_link(params, opts \\ []) do
    GenServer.start_link(__MODULE__, params, opts)
  end

  def stop(pid) do
    GenServer.stop(pid)
  end

  def init(params) do
    with port <- Keyword.get(params, :port, @port),
         timeout <- Keyword.get(params, :timeout, @to),
         sup_opts <- Keyword.get(params, :sup_opts, []),
         handler_module <- Keyword.get(params, :handler_module, Tcp.Client.Handler.Default),
         handler_args <- Keyword.get(params, :handler_args, nil),
         true <- is_atom(handler_module),
         {:ok, sup_pid} <- Server.Supervisor.start_link(sup_opts) do
      {:ok,
       %Server{
         tcp_port: port,
         timeout: timeout,
         sup_pid: sup_pid,
         handler_module: handler_module,
         handler_args: handler_args
       }, {:continue, :setup}}
    else
      _error ->
        {:error, :einval}
    end
  end

  def terminate(:normal, _state), do: nil

  def terminate(reason, state) do
    Logger.error("(#{__MODULE__}) Error: #{inspect(reason)}")
    :gen_tcp.close(state.listener)
  end

  def handle_continue(:setup, state) do
    new_state = listener_setup(state)
    {:noreply, new_state}
  end

  defp listener_setup(state) do
    case :gen_tcp.listen(state.tcp_port, [:binary, packet: :raw, active: true, reuseaddr: true]) do
      {:ok, listener} ->
        {:ok, {ip, _port}} = :inet.sockname(listener)
        accept = Task.async(fn -> accept(state, listener) end)
        %Server{state | ip: ip, acceptor_pid: accept, listener: listener}

      {:error, :eaddrinuse} ->
        Logger.error("(#{__MODULE__}) Error: A listener is still alive")
        close_alive_sockets(state.tcp_port)
        Process.sleep(100)
        listener_setup(state)

      {:error, reason} ->
        Logger.error("(#{__MODULE__}) Error in Listen: #{reason}")
        Process.sleep(1000)
        listener_setup(state)
    end
  end

  def close_alive_sockets(port) do
    Port.list()
    |> Enum.filter(fn x -> Port.info(x)[:name] == 'tcp_inet' end)
    |> Enum.filter(fn x ->
      {:ok, {{0, 0, 0, 0}, port}} == :inet.sockname(x) ||
        {:ok, {{127, 0, 0, 1}, port}} == :inet.sockname(x)
    end)
    |> Enum.each(fn x -> :gen_tcp.close(x) end)
  end

  defp accept(%{sup_pid: sup_pid, handler_module: handler_module, handler_args: handler_args} = state, listener) do
    case :gen_tcp.accept(listener) do
      {:ok, socket} ->
        {:ok, pid} =
          Server.Supervisor.start_child(sup_pid, handler_module, [handler_args])

        Logger.debug(
          "(#{__MODULE__}) New Client socket: #{inspect(socket)}, pid: #{inspect(pid)}"
        )

        case :gen_tcp.controlling_process(socket, pid) do
          :ok ->
            nil

          error ->
            Logger.error("(#{__MODULE__}) Error in controlling process: #{inspect(error)}")
        end

        accept(state, listener)

      {:error, reason} ->
        Logger.error("(#{__MODULE__}) Error Accept: #{inspect(reason)}")
        exit(reason)
    end
  end
end
