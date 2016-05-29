defmodule TicketToRide.Client do
  use Connection

  require Logger

  # API

  def start_link(opts \\ []) do
    Connection.start_link(__MODULE__, opts, [name: __MODULE__])
  end

  def list do
    Connection.call(__MODULE__, :list)
  end

  # Callbacks

  @timeout 5000
  @retries 3
  def init(args) do
    ip = args[:ip]
    port = args[:port]

    {:connect, :init, %{ip: ip, port: port, conn: nil, retries: @retries}}
  end

  def connect(_, %{retries: 0} = state) do
    {:stop, :connection_failed, state}
  end

  def connect(_, %{ip: ip, port: port} = state) do
    Logger.debug "Attempting to connect to #{ip}:#{port}..."
    case Socket.TCP.connect(ip, port, packet: :line) do
      {:ok, conn} ->
        Logger.debug "Connect successful."
        {:ok, %{state | conn: conn}}
      {:error, _} ->
        Logger.debug "Connect failed. Trying again in #{@timeout} ms..."
        new_state = %{state | retries: state.retries - 1}
        {:backoff, @timeout, new_state}
    end
  end

  def handle_call(:list, _from, state) do
    send_msg(state.conn, [:list, "\n"])
    {:reply, recv_msg(state.conn), state}
  end

  # Private

  defp send_msg(conn, payload) do
    msg = Msgpax.pack!(payload)
    Socket.Stream.send!(conn, msg)
  end

  defp recv_msg(conn) do
    Socket.Stream.recv!(conn)
    |> Msgpax.unpack!
  end
end
