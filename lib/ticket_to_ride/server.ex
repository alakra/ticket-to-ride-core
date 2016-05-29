defmodule TicketToRide.Server do
  use GenServer

  alias TicketToRide.ServerHandler

  require Logger

  # API

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, [name: __MODULE__])
  end

  def games do
    GenServer.call(__MODULE__, :games)
  end

  # Callbacks

  @acceptors 10

  def init(args) do
    Logger.info "Starting server on tcp://#{args[:ip]}:#{args[:port]} (max connections: #{args[:limit]})"

    {:ok, listener} = :ranch.start_listener(TicketToRide, @acceptors, :ranch_tcp,
      [ip: parse_ip(args[:ip]), port: args[:port], max_connections: args[:limit]],
      ServerHandler, [])

    {:ok, %{listener: listener, games: []}}
  end

  def handle_call(:games, _from, state) do
    {:reply, state.games, state}
  end

  # Private

  defp parse_ip(ip) do
    {:ok, ip_address} = ip
    |> String.to_char_list
    |> :inet.parse_address

    ip_address
  end
end
