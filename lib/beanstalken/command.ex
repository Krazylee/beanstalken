defmodule Beanstalken.Command do

  def send(socket, command) do
    :gen_tcp.send(socket, "stats\r\n")
  end
end
