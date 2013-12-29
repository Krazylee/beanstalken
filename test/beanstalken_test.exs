defmodule BeanstalkenTest do
  use ExUnit.Case

  alias Beanstalken.State
  alias Beanstalken.Response

  test "beanstalken should connect to beanstalkd" do
    { :ok, pid } = Beanstalken.connect()
    assert pid
  end

  test "handle call" do
    { :ok, pid } = Beanstalken.connect()
    :gen_server.call(pid, "unknown")
  end

  test "parse_digits should return the number from a string" do
    sample_string = "1234\r\nthis is sample"
    { :ok, digits, string } = Response.parse_digits(sample_string)
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
    sample_string = "UNKNOWN_FORMAT\r\nrest"
    { :ok, type, _ } = Response.parse(sample_string)
    assert type == :unknown_format
  end

  test "parse bad format" do
    sample_string = "BAD_FORMAT\r\nrest"
    { :ok, type, _ } = Response.parse(sample_string)
    assert type == :bad_format
  end

  test "parse int" do
    sample_string = "8\r\n"
    { :ok, {name, id}, _ } = Response.parse_int(sample_string, :inserted)
    assert id == 8
  end

  test "handle put command" do
    { :ok, pid } = Beanstalken.connect()
    :gen_server.call(pid, {:put, [pri: 10, delay: 0, ttr: 100], "test"})
  end

end
