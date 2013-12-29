defmodule BeanstalkenTest do
  use ExUnit.Case

  alias Beanstalken.Response
  alias Beanstalken.Command

  test "beanstalken should connect to beanstalkd" do
    { :ok, pid } = Beanstalken.connect()
    assert pid
  end

  test "handle call" do
    { :ok, pid } = Beanstalken.connect()
    :gen_server.call(pid, {:unknown})
  end

  test "parse_digits should return the number from a string" do
    sample_string = "1234\r\nthis is sample"
    { :ok, digits, _ } = Response.parse_digits(sample_string)
    assert digits == 1234
  end

  test "parse_body should return the response body" do
    sample_string = "8\r\nresponse\r\nrest"
    { :ok, body, _ } = Response.parse_body(sample_string)
    assert body == "response"
  end

  test "parse ok response" do
    sample_string = "OK 8\r\nresponse\r\nrest"
    { :ok, body, _ } = Response.parse(sample_string)
    assert body == "response"
  end

  test "parse unknown format" do
    sample_string = "UNKNOWN_COMMAND\r\nrest"
    { :ok, type, _ } = Response.parse(sample_string)
    assert type == :unknown_command
  end

  test "parse bad format" do
    sample_string = "BAD_FORMAT\r\nrest"
    { :ok, type, _ } = Response.parse(sample_string)
    assert type == :bad_format
  end

  test "parse int" do
    sample_string = "8\r\n"
    { :ok, {name, id}, _ } = Response.parse_int(sample_string, :inserted)
    assert name == :inserted
    assert id == 8
  end

  test "parse string" do
    sample_string = "tube\r\n"
    { :ok, {name, string}, _ } = Response.parse_string(sample_string, :using)
    assert name == :using
    assert string == "tube"
  end

  test "parse job" do
    sample_string = "10 5\r\nhello\r\n"
    { :ok, {name, id, body}, _ } = Response.parse_job(sample_string, :reserved)
    assert name == :reserved
    assert id == 10
    assert body == "hello"
  end

  test "parse id" do
    sample_string = "10 5\r\nhello\r\n"
    { :ok, id, _ }  = Response.parse_id(sample_string)
    assert id == 10 
  end

  test "to_command_string" do
    command = {:use, "tube_test"}
    assert "use tube_test\r\n" == Command.to_command_string(command)
  end

  test "handle put command" do
    { :ok, pid } = Beanstalken.connect()
    :gen_server.call(pid, {:put, [pri: 10, delay: 0, ttr: 100], "test"})
  end

  test "handle use command" do
    { :ok, pid } = Beanstalken.connect()
    { :using, tube_name } = :gen_server.call(pid, {:use, "test_tube"})
    assert tube_name == "test_tube"
  end

  test "handle reserve command" do
    { :ok, pid } = Beanstalken.connect()
    { :reserved, id, _ } = :gen_server.call(pid, {:reserve})
    assert is_number(id)
  end

  test "handle delete command" do
    { :ok, pid } = Beanstalken.connect()
    name = :gen_server.call(pid, {:delete, 99})
    assert name == :not_found
  end

  test "handle release command" do
    { :ok, pid } = Beanstalken.connect()
    { :reserved, id, _ } = :gen_server.call(pid, {:reserve})
    :released = :gen_server.call(pid, {:release, id, 10, 0})
    :not_found = :gen_server.call(pid, {:release, 99, 10, 0})
  end

  test "handle bury command" do
    { :ok, pid } = Beanstalken.connect()
    { :reserved, id, _ } = :gen_server.call(pid, {:reserve})
    :buried = :gen_server.call(pid, {:bury, id, 1})
    :not_found = :gen_server.call(pid, {:bury, 99, 1})
  end

  test "handle touch command" do
    { :ok, pid } = Beanstalken.connect()
    { :reserved, id, _ } = :gen_server.call(pid, {:reserve})
    :touched = :gen_server.call(pid, {:touch, id, 1})
    :not_found = :gen_server.call(pid, {:touch, 99, 1})
  end

  test "handle watching/ignore command" do
    { :ok, pid } = Beanstalken.connect()
    { :watching, count } = :gen_server.call(pid, {:watch, "test_tube"})
    { :watching, count } = :gen_server.call(pid, {:ignore, "test_tube"})
    assert is_number(count)
  end
end
