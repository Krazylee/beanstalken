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

  # errors
  def parse(<<"OUT_OF_MEMORY\r\n", resp::binary>>) do
    { :ok, :out_of_memory, resp }
  end

  def parse(<<"INTERNAL_ERROR\r\n", resp::binary>>) do
    { :ok, :internal_error, resp }
  end

  def parse(<<"BAD_FORMAT\r\n", resp::binary>>) do
    { :ok, :bad_format, resp }
  end

  def parse(<<"UNKNOWN_COMMAND\r\n", resp::binary>>) do
    { :ok, :unknown_command, resp }
  end

  # put responses
  def parse(<<"INSERTED ", resp::binary>>) do
    parse_int(resp, :inserted)
  end

  def parse(<<"BURIED ", resp::binary>>) do
    parse_int(resp, :buried)
  end

  def parse(<<"EXPECTED_CRLF\r\n", resp::binary>>) do
    { :ok, :expected_crlf, resp }
  end

  def parse(<<"JOB_TOO_BIG\r\n", resp::binary>>) do
    { :ok, :job_too_big, resp }
  end

  def parse(<<"DRAINING\r\n", resp::binary>>) do
    { :ok, :draining, resp }
  end

  # use responses
  def parse(<<"USING ", resp::binary>>) do
    parse_string(resp, :using)
  end

  # reserve response
  def parse(<<"RESERVED ", resp::binary>>) do
    parse_job(resp, :reserved)
  end

  def parse(<<"DEADLINE_SOON\r\n", resp::binary>>) do
    { :ok, :deadline_soon, resp }
  end

  def parse(<<"TIMED_OUT\r\n", resp::binary>>) do
    { :ok, :timed_out, resp }
  end

  # delete responsed
  def parse(<<"DELETED\r\n", resp::binary>>) do
    { :ok, :deleted, resp }
  end

  def parse(<<"NOT_FOUND\r\n", resp::binary>>) do
    { :ok, :not_found, resp }
  end

  # release responses
  def parse(<<"RELEASED\r\n", resp::binary>>) do
    { :ok, :released, resp }
  end

  # bury responses
  def parse(<<"BURIED\r\n", resp::binary>>) do
    { :ok, :buried, resp }
  end

  # touch responses
  def parse(<<"TOUCHED\r\n", resp::binary>>) do
    { :ok, :touched, resp }
  end
  
  # watch/ignore responses
  def parse(<<"WATCHING ", resp::binary>>) do
    parse_int(resp, :watching)
  end

  # peek responses
  def parse(<<"FOUND ", resp::binary>>) do
    parse_job(resp, :found)
  end

  # kick responses
  def parse(<<"KICKED ", resp::binary>>) do
    parse_int(resp, :kicked)
  end

  def parse(<<"PAUSED\r\n", resp::binary>>) do
    { :ok, :paused, resp }
  end

  def parse(<<"OK ", resp::bytes>>) do
    case parse_body(resp) do
      { :ok, body, rest } ->
        { :ok, body, rest }
      :more ->
        :more
    end
  end

  def parse(_) do
    :more
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

  def parse_job(body, name) do
    case parse_id(body) do
      { :ok, id, rest } ->
        case parse_body(rest) do
          { :ok, content, rest2 } ->
            { :ok, { name, id, content }, rest2 }
          :more ->
            :more
        end
      :more ->
        :more
    end
  end

  def parse_id(body) do
    case parse_digits(body) do
      { :ok, number, <<" ", rest::binary>> } ->
        { :ok, number, rest }
      _ ->
        :more
    end
  end

  def parse_string(body, name) do
    parse_string(body, name, [])
  end

  def parse_string(<<"\r\n", rest::binary>>, name, acc) do
    { :ok, { name, to_string(Enum.reverse(acc)) }, rest }
  end

  def parse_string(<<first, rest::bytes>>, name, acc) do
    parse_string(rest, name, [first|acc])
  end

  def parse_int(body, name) do
    case parse_digits(body) do
      { :ok, int, <<"\r\n", rest::binary>>} ->
        { :ok, {name, int}, rest }
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
