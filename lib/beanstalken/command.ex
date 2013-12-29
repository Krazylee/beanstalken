defmodule Beanstalken.Command do

  def send(socket, command) do
    :gen_tcp.send(socket, to_command_string(command))
  end

  def send(socket, command, data) do
    :gen_tcp.send(socket, "put 10 0 100 4\r\ntest\r\n")
  end

  def to_command_string(command) when is_tuple(command) do
    to_command_string(tuple_to_list(command)) 
  end

  def to_command_string(command) when is_list(command) do
    to_command_string(command, [])
  end

  def to_command_string([], acc) do
    to_string(Enum.reverse(["\r\n"|acc]))
  end

  def to_command_string([head|tail], []) do
    to_command_string(tail, [to_string(head)])
  end

  def to_command_string([head|tail], acc) do
    to_command_string(tail, [to_string(head), " "|acc])
  end
end
