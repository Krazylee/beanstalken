defmodule Beanstalken.Command do

  def send(socket, command) do
    :gen_tcp.send(socket, "stats\r\n")
  end

  def send(socket, command, data) do
    IO.puts data
    :gen_tcp.send(socket, "put 10 0 100 4\r\ntest\r\n")
  end
end
