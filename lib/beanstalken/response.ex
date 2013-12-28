defmodule Beanstalken.Response do
  
  def recv(socket) do
    recv(socket, "")
  end

  def recv(socket, data) do
    case :gen_tcp.recv(socket, 0) do
      { :ok, packet } ->
        new_data = [data, packet]
        case parse(to_string(new_data)) do
          :more ->
            recv(socket, new_data)
          { :ok, reply, new_state } ->
            { :ok, reply, new_state }
        end
      error ->
        error
    end
  end

  def parse(<<"OK ", resp::bytes>>) do
    case parse_body(resp) do
      { :ok, body, rest } ->
        { :ok, body, rest }
      :more ->
        :more
    end
  end

  def parse_body(body) do
    case parse_digits(body) do
      { :ok, length, <<"\r\n", rest::binary>> } ->
        case rest do
          <<content::[binary, size(length)], "\r\n", rest2::binary>> ->
            { :ok, content, rest2 }
          _ ->  
            :more
        end
      _ ->
        :more
    end
  end

  def parse_digits(string) do
    parse_digits(string, [])
  end

  def parse_digits(string, acc) do
    case string do
      <<first, rest::bytes>> when first >= ?0 and first <= ?9 ->
        parse_digits(rest, [first|acc])
      _ ->
        { :ok, list_to_integer(Enum.reverse(acc)), string}
    end
  end

end
