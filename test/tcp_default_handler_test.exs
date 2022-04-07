defmodule TcpDefaultHandlerTest do
  use ExUnit.Case
  require Logger
  import ExUnit.CaptureLog

  setup_all do
    {:ok, _s_pid} = Tcp.Server.start_link(port: 4005)
    :ok
  end

  test "init/1" do
    logs =
      capture_log(fn ->
        :gen_tcp.connect({127, 0, 0, 1}, 4005, [:binary, packet: :raw], 1000)
        Process.sleep(200)
      end)

    assert logs =~ "(Elixir.Tcp.Client.Handler.Default) Start Handler"
  end

  test "handle_msg/3" do
    {:ok, socket} = :gen_tcp.connect({127, 0, 0, 1}, 4005, [:binary, packet: :raw], 2000)

    logs =
      capture_log(fn ->
        :gen_tcp.send(socket, "handle_msg/3 Test")
        Process.sleep(200)
      end)

    assert logs =~ "(Elixir.Tcp.Client.Handler.Default) Received: handle_msg/3 Test"
  end

  test "handle_close/2" do
    {:ok, socket} = :gen_tcp.connect({127, 0, 0, 1}, 4005, [:binary, packet: :raw], 2000)

    logs =
      capture_log(fn ->
        :gen_tcp.close(socket)
        Process.sleep(200)
      end)

    assert logs =~ "(Elixir.Tcp.Client.Handler.Default) Socket closed"
  end
end
