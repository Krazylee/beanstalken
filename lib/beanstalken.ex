defmodule Beanstalken do
  use Application

  # See http://elixir-lang.org/docs/stable/Application.Behaviour.html
  # for more information on OTP Applications
  def start(_type, _args) do
    Beanstalken.Supervisor.start_link
  end

  def connect(host, port, timeout) do
    :gen_server.start_link(Beanstalken.Connection, {host, port, timeout}, [])
  end

  def connect(host, port) do
    connect(host, port, 5000)
  end

  def connect(host) do
    connect(host, 11300)
  end

  def connect() do
    # host needs to be a charlist
    connect('localhost')
  end
end
