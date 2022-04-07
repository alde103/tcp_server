defmodule TcpCustomHandlerTest do
  use ExUnit.Case
  require Logger

  setup do
    {:ok, s_pid} = Tcp.Server.start_link(port: 4006, handler_args: self(), handler_module: Handler.Mock)
    {:ok, %{s_pid: s_pid}}
  end

  test "init/1", %{s_pid: _s_pid} do
    Tcp.Server.start_link(port: 4007, handler_args: self(), handler_module: Handler.Mock)

    :gen_tcp.connect({127, 0, 0, 1}, 4007, [:binary, packet: :raw], 1000)

    assert_receive(:init, 1000)
  end

  test "handle_msg/3", %{s_pid: _s_pid} do
    Tcp.Server.start_link(port: 4008, handler_args: self(), handler_module: Handler.Mock)

    {:ok, socket} = :gen_tcp.connect({127, 0, 0, 1}, 4008, [:binary, packet: :raw], 1000)

    Process.sleep(100)

    :gen_tcp.send(socket, "handle_msg/3 Test")

    assert_receive({:handle_msg, "handle_msg/3 Test"}, 1000)
  end

  test "handle_close/2", %{s_pid: _s_pid} do
    Tcp.Server.start_link(port: 4009, handler_args: self(), handler_module: Handler.Mock)

    {:ok, socket} = :gen_tcp.connect({127, 0, 0, 1}, 4009, [:binary, packet: :raw], 1000)

    Process.sleep(100)

    :gen_tcp.close(socket)

    assert_receive(:handle_close, 1000)
  end
end
