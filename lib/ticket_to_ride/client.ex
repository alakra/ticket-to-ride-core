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

  def register(user, pass) do
    Connection.call(__MODULE__, {:register, user, pass})
  end

  def login(user, pass) do
    Connection.call(__MODULE__, {:login, user, pass})
  end

  def create(token, options) do
    Connection.call(__MODULE__, {:create, token, options})
  end

  def join(token, game_id) do
    Connection.call(__MODULE__, {:join, token, game_id})
  end

  def leave(token, game_id) do
    Connection.call(__MODULE__, {:leave, token, game_id})
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
        Logger.debug "Connect successful"
        {:ok, %{state | conn: conn}}
      {:error, _} ->
        Logger.debug "Connect failed. Trying again in #{@timeout} ms..."
        new_state = %{state | retries: state.retries - 1}
        {:backoff, @timeout, new_state}
    end
  end

  def handle_call(:list, _from, state) do
    send_msg(state.conn, [:list])

   case recv_msg(state.conn) do
     list -> {:reply, {:ok, list}, state}
     %{"error" => msg} -> {:reply, {:ok, []}, state}
   end
  end

  def handle_call({:register, user, pass}, _from, state) do
    send_msg(state.conn, [:register, user, pass])

    case recv_msg(state.conn) do
      "registered" -> {:reply, {:ok, :registered}, state}
      %{"error" => msg} -> {:reply, {:error, msg}, state}
    end
  end

  def handle_call({:login, user, pass}, _from, state) do
    send_msg(state.conn, [:login, user, pass])

    case recv_msg(state.conn) do
      token -> {:reply, {:ok, token}, state}
      %{"error" => msg} -> {:reply, {:error, msg}, state}
    end
  end

  def handle_call({:create, token, options}, _from, state) do
    send_msg(state.conn, [:create, token, options])

    case recv_msg(state.conn) do
      game_id -> {:reply, {:ok, game_id}, state}
      %{"error" => msg} -> {:reply, {:error, msg}, state}
    end
  end

  def handle_call({:join, token, game_id}, _from, state) do
    send_msg(state.conn, [:join, token, game_id])

    case recv_msg(state.conn) do
      %{"joined" => actual_id} -> {:reply, {:ok, {:joined, actual_id}}, state}
      %{"error" => msg} -> {:reply, {:error, msg}, state}
    end
  end

  def handle_call({:leave, token, game_id}, _from, state) do
    send_msg(state.conn, [:leave, token, game_id])

    case recv_msg(state.conn) do
      %{"ok" => _msg} -> {:reply, {:ok, :left}, state}
      %{"error" => msg} -> {:reply, {:error, msg}, state}
    end
  end

  def terminate(:connection_failed, _) do
    IO.puts "Terminating: Client failed to connect."
    System.halt(1)
  end

  # Private

  defp send_msg(conn, payload) do
    msg = Msgpax.pack!([payload|["\n"]])
    Socket.Stream.send!(conn, msg)
  end

  defp recv_msg(conn) do
    [payload|_] = Socket.Stream.recv!(conn) |> Msgpax.unpack!
    payload
  end
end
