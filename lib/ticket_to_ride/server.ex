defmodule TicketToRide.Server do
  use GenServer

  alias TicketToRide.{ServerHandler, Player, Games, Game}

  require Logger

  # API

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, [name: __MODULE__])
  end

  def games do
    GenServer.call(__MODULE__, :games)
  end

  def register(user, pass) do
    GenServer.call(__MODULE__, {:register, user, pass})
  end

  def login(user, pass) do
    GenServer.call(__MODULE__, {:login, user, pass})
  end

  def create(token, options) do
    GenServer.call(__MODULE__, {:create, token, options})
  end

  def join(token, game_id) do
    GenServer.call(__MODULE__, {:join, token, game_id})
  end

  def leave(token, game_id) do
    GenServer.call(__MODULE__, {:leave, token, game_id})
  end

  # Callbacks

  @acceptors 10

  def init(args) do
    Logger.info "Starting server on tcp://#{args[:ip]}:#{args[:port]} (max connections: #{args[:limit]})"

    {:ok, listener} = :ranch.start_listener(TicketToRide, @acceptors, :ranch_tcp,
      [ip: parse_ip(args[:ip]), port: args[:port], max_connections: args[:limit]],
      ServerHandler, [])

    {:ok, %{listener: listener}}
  end

  def handle_call(:games, _from, state) do
    case Games.list do
      {:ok, list} -> {:reply, {:ok, list}, state}
      {:error, msg} -> {:reply, {:error, msg}, state}
    end
  end

  def handle_call({:register, user, pass}, _from, state) do
    case Player.DB.register(user, pass) do
      :ok -> {:reply, :ok, state}
      {:error, msg} -> {:reply, {:error, msg}, state}
    end
  end

  def handle_call({:login, user, pass}, _from, state) do
    case Player.Session.new(user, pass) do
      {:ok, session} -> {:reply, {:ok, session.token}, state}
      {:error, msg} -> {:reply, {:error, msg}, state}
    end
  end

  def handle_call({:create, token, options}, _from, state) do
    case Player.Session.get(token) do
      {:ok, user_session} ->
        opts = Keyword.put(options, :user_id, user_session.id)
        {:reply, Games.create(opts), state}
      other ->
        {:reply, other, state}
    end
  end

  def handle_call({:join, token, game_id}, _from, state) do
    case Player.Session.get(token) do
      {:ok, user_session} -> join_game(game_id, user_session.id, state)
      other -> {:reply, other, state}
    end
  end

  def handle_call({:leave, token, game_id}, _from, state) do
    case Player.Session.get(token) do
      {:ok, user_session} -> leave_game(game_id, user_session.id, state)
      other -> {:reply, other, state}
    end
  end

  # Private

  defp parse_ip(ip) do
    {:ok, ip_address} = ip
    |> String.to_char_list
    |> :inet.parse_address

    ip_address
  end

  defp join_game(game_id, user_id, state) do
    case Games.join(game_id, user_id) do
      :ok ->
        {:reply, {:ok, :joined}, state}
      {:error, msg} ->
        {:reply, {:error, msg}, state}
    end
  end

  defp leave_game(game_id, user_id, state) do
    case Games.leave(game_id, user_id) do
      :ok ->
        {:reply, {:ok, :left}, state}
      {:error, msg} ->
        {:reply, {:error, msg}, state}
    end
  end
end
