defmodule TicketToRide.Game do
  defstruct [
    :id,
    :owner,
    :users,
    :gamestate,
    :max_players
  ]

  use GenServer

  alias TicketToRide.State
  alias TicketToRide.Games.Index

  require Logger

  # API

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, [])
  end

  def id(game) do
    GenServer.call(game, :id)
  end

  def status(game) do
    GenServer.call(game, :status)
  end

  def begin(game) do
    GenServer.call(game, :start)
  end

  def join(game, user_session) do
    GenServer.call(game, {:join, user_session})
  end

  def leave(game, user_session) do
    GenServer.call(game, {:leave, user_session})
  end

  # Callback

  @default_max_players 4

  def init(opts) do
    {:ok, %__MODULE__{
        id: UUID.uuid1(:hex),
        owner: opts[:user_session],
        users: [opts[:user_session]],
        max_players: opts[:max] || @default_max_players,
        gamestate: nil}
    }
  end

  def handle_call(:id, _from, state) do
    {:reply, state.id, state}
  end

  def handle_call(:status, _from, state) do
    # TBD
  end

  def handle_call({:join, user_session}, _from, state) do
    with :ok <- validate_not_full(state),
         :ok <- validate_no_duplicate_players(user_session, state) do
      {:reply, :ok, %{state | users: [user_session|state.users]}}
    else
      {:error, msg} -> {:reply, {:error, msg}, state}
    end
  end

  def handle_call({:leave, user_session}, _from, state) do
    with :ok <- validate_user_joined(user_session, state) do
      {:reply, :ok, %{state | users: List.delete(state.users, user_session)}}
    else
      {:error, msg} -> {:reply, {:error, msg}, state}
    end
  end

  def handle_call(:start, _from, state) do
    {:reply, :ok, State.generate(state.users)}
  end

  def terminate(reason, state) do
    Logger.info("Game exiting [#{state.id}]: #{reason}")
    Index.remove(state.id)
  end

  # Private

  defp validate_not_full(state) do
    if Enum.count(state.users) <= state.max_players do
      :ok
    else
      {:error, :full}
    end
  end

  defp validate_no_duplicate_players(user_session, state) do
    if is_joined?(user_session, state.users) do
      {:error, :already_joined}
    else
      :ok
    end
  end

  defp validate_user_joined(user_session, state) do
    if is_joined?(user_session, state.users)do
      :ok
    else
      {:error, :not_joined}
    end
  end

  defp is_joined?(user_session, users) do
    !!Enum.find(users, false, fn user -> user.token == user_session.token end)
  end
end
