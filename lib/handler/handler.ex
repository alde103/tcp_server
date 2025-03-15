defmodule Tcp.Client.Handler do
  @type socket :: any()
  @type data :: binary()
  @type state :: any()
  @type reason :: atom()

  @callback handle_msg(socket, data, state) :: term()
  @callback handle_close(socket, state) :: term()
  @callback handle_error(socket, reason, state) :: term()
  @callback handle_timeout(state) :: term()

  defmacro __using__(opts) do
    quote location: :keep, bind_quoted: [opts: opts] do
      use GenServer, Keyword.drop(opts, [:configuration])
      @behaviour Tcp.Client.Handler

      alias __MODULE__

      def start_link(user_initial_params \\ []) do
        GenServer.start_link(__MODULE__, user_initial_params, unquote(opts))
      end

      def init([user_initial_params]) do
        send self(), :init
        {:ok, user_initial_params}
      end

      @impl true
      def handle_info(:init, user_initial_params) do
        {:noreply, apply(__MODULE__, :init, [user_initial_params])}
      end

      @impl true
      def handle_info({:tcp, socket, data}, state) do
        {:noreply, apply(__MODULE__, :handle_msg, [socket, data, state])}
      end

      @impl true
      def handle_info({:tcp_closed, socket}, state) do
        {:stop, :normal, apply(__MODULE__, :handle_close, [socket, state])}
      end

      @impl true
      def handle_info({:tcp_error, socket, reason}, state) do
        {:stop, :normal, apply(__MODULE__, :handle_error, [socket, reason, state])}
      end

      @impl true
      def handle_info(:timeout, state) do
        {:stop, :normal, apply(__MODULE__, :handle_timeout, [state])}
      end

      @impl true
      def terminate(:normal, _state), do: nil

      def terminate(_reason, state) do
        :gen_tcp.close(state.socket)
      end

      def handle_msg(socket, data, state) do
        require Logger
        Logger.warning("No handle_msg/3 clause in #{__MODULE__} provided for #{inspect({socket, data, state})}")
        state
      end

      def handle_close(socket, state) do
        require Logger
        Logger.warning("No handle_close/2 clause in #{__MODULE__} provided for #{inspect({socket, state})}")
        state
      end

      def handle_error(socket, reason, state) do
        require Logger
        Logger.warning("No handle_error/3 clause in #{__MODULE__} provided for #{inspect({socket, reason, state})}")
        state
      end

      def handle_timeout(state) do
        require Logger
        Logger.warning("No handle_timeout/1 clause in #{__MODULE__} provided for #{inspect(state)}")
        state
      end

      defoverridable  handle_msg: 3,
                      handle_close: 2,
                      handle_error: 3,
                      handle_timeout: 1

    end
  end
end
