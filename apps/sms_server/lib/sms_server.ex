defmodule SMSServer do
  use Application
  require Logger

  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    children = [
      supervisor(Task.Supervisor, [[name: SMSServer.TaskSupervisor]]),
      worker(Task, [SMSServer, :accept, [1491]]),
    ]

    opts = [strategy: :one_for_one, name: SMSServer.Supervisor]
    Supervisor.start_link(children, opts)
  end

  def accept(port) do
    {:ok, socket} = :gen_tcp.listen(port, [:binary, packet: :raw, active: false, reuseaddr: true])
    Logger.info "Accepting incoming connections on port #{port}"
    loop_acceptor(socket)
  end

  defp loop_acceptor(socket) do
    {:ok, client} = :gen_tcp.accept(socket)
    {:ok, pid} = Task.Supervisor.start_child(SMSServer.TaskSupervisor, fn -> wait_for_stx(client) end)
    case :gen_tcp.controlling_process(client, pid) do
      {:error, :badarg} -> :gen_tcp.close(client)
      :ok -> :ok
    end
    loop_acceptor(socket)
  end

  defp wait_for_stx(socket) do
    result = case read_byte(socket) do
     {:ok, <<2>>} -> read_to_etx(socket, [])
     {:ok, char} -> {:noop, char}
     something -> something
    end
    respond(socket, result)
    wait_for_stx(socket)
  end

  defp read_to_etx(socket, buffer) do
    case read_byte(socket) do
      {:ok, <<3>>} -> {:ok, buffer}
      {:ok, char} -> read_to_etx(socket, buffer ++ [char])
    end
  end

  defp read_byte(socket) do
    :gen_tcp.recv(socket, 1)
  end

  defp respond(socket, {:ok, text}) do
    Logger.info text
    {ot, command} = EMI.Parser.parse(text)
    {:ok, response} = EMI.Parser.run({ot, command})
    :gen_tcp.send(socket, <<2>> <> response <> <<3>>)
  end

  defp respond(socket, {:noop, _}) do
  end

  defp respond(socket, {:error, :unknown_command}) do
    :gen_tcp.send(socket, "MALFORMED\r\n")
  end

  defp respond(socket, {:error, :closed}) do
    Logger.info "Client disconnected"
    exit(:shutdown)
  end
end
