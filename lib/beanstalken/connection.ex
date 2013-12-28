defmodule Beanstalken.Connection do
  use GenServer.Behaviour

  defrecord State, socket: nil, buffer: ""

  def init({ host, port, timeout }) do
    IO.puts "#{host}, #{port}, #{timeout}"
    case :gen_tcp.connect(host, port, [:binary, {:packet, 0}, {:active, false}]) do
      { :ok, socket } ->
        { :ok, State.new(socket: socket) }
      error ->
        { :stop, error }
    end
  end

  def handle_call(command, _from, State[socket: socket, buffer: buffer] = state) do
    Beanstalken.Command.send(socket, command)
    { :ok, reply, new_buffer } = Beanstalken.Response.recv(socket, buffer)
    { :reply, reply, state.update(buffer: new_buffer) }
  end

  def handle_cast({ :push, new }, stack) do
    { :noreply, [new|stack] }
  end
end
