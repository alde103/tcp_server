defmodule TcpServerTest do
  use ExUnit.Case
  require Logger
  import ExUnit.CaptureLog

  test "start_link/1" do
    {:ok, s_pid} = Tcp.Server.start_link(port: 4000)
    assert is_pid(s_pid)
  end

  test "Accepts Multiple Clients" do
    {:ok, s_pid} = Tcp.Server.start_link(port: 4001)
    assert is_pid(s_pid)

    # client 1
    logs =
      capture_log(fn ->
        :gen_tcp.connect({127, 0, 0, 1}, 4001, [:binary, packet: :raw], 1000)
        Process.sleep(100)
      end)

    assert logs =~ "New Client socket"

    # client 2
    assert match?({:ok, _socket},:gen_tcp.connect({127, 0, 0, 1}, 4001, [:binary], 1000))

    # client 3
    assert match?({:ok, _socket},:gen_tcp.connect({127, 0, 0, 1}, 4001, [:binary], 1000))
  end
end
