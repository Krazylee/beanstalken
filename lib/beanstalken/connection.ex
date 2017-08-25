defmodule Beanstalken.Connection do
  use GenServer

  alias Beanstalken.State
  alias Beanstalken.Command
  alias Beanstalken.Response

  def init({ host, port, timeout }) do
    case :gen_tcp.connect(host, port, [:binary, {:packet, 0}, {:active, false}], timeout) do
      { :ok, socket } ->
        { :ok, %State{socket: socket} }
      error ->
        { :stop, error }
    end
  end

  def handle_call({:put, params, data}, _from, %State{socket: socket, buffer: buffer} = state) do
    pri = params[:pri]
    delay = params[:delay]
    ttr = params[:ttr]
    bytes = if params[:bytes], else: byte_size(data)
    Command.send(socket, {:put, pri, delay, ttr, bytes}, data)
    { :ok, reply, new_buffer } = Response.recv(socket, buffer)
    { :reply, reply, %{state | buffer: new_buffer} }
  end

  def handle_call(command, _from, %State{socket: socket, buffer: buffer} = state) do
    Command.send(socket, command)
    { :ok, reply, new_buffer } = Response.recv(socket, buffer)
    { :reply, reply, %{state | buffer: new_buffer} }
  end

  def handle_cast({ :stop }, state) do
    { :stop, :normal, state }
  end

  def handle_cast(_msg, state) do
    { :no_reply, state }
  end

  def terminate(:normal, %State{socket: socket, buffer: _} = _) do
    :gen_tcp.close(socket)
    :ok
  end
end
