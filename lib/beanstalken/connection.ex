defmodule Beanstalken.Connection do
  use GenServer.Behaviour

  defrecord State, socket: nil, buffer: ""
  alias Beanstalken.Command
  alias Beanstalken.Response

  def init({ host, port, timeout }) do
    case :gen_tcp.connect(host, port, [:binary, {:packet, 0}, {:active, false}]) do
      { :ok, socket } ->
        { :ok, State.new(socket: socket) }
      error ->
        { :stop, error }
    end
  end

  def handle_call({:put, params, data}, _from, State[socket: socket, buffer: buffer] = state) do
    pri = params[:pri]
    delay = params[:delay]
    ttr = params[:ttr]
    bytes = if params[:bytes], else: size(data) 
    IO.puts bytes
    Command.send(socket, {:put, pri, delay, ttr, bytes}, data)
    { :ok, reply, new_buffer } = Response.recv(socket, buffer)
    { :reply, reply, state.update(buffer: new_buffer) }
  end

  def handle_call(command, _from, State[socket: socket, buffer: buffer] = state) do
    Command.send(socket, command)
    { :ok, reply, new_buffer } = Response.recv(socket, buffer)
    { :reply, reply, state.update(buffer: new_buffer) }
  end

  def handle_cast({ :push, new }, stack) do
    { :noreply, [new|stack] }
  end
end
