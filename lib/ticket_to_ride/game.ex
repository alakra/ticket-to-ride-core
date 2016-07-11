defmodule TicketToRide.Game do
  defstruct [
    :id,
    :owner,
    :turn_length,
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

  def join(game, user_id) do
    GenServer.call(game, {:join, user_id})
  end

  def leave(game, user_id) do
    GenServer.call(game, {:leave, user_id})
  end

  # Callback

  @default_max_players 4
  @default_turn_length 60_000

  def init(opts) do
    {:ok, %__MODULE__{
        id: UUID.uuid1(:hex),
        owner: opts[:user_id],
        users: [opts[:user_id]],
        turn_length: opts[:turn_length] || @default_turn_length,
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

  def handle_call({:join, user_id}, _from, state) do
    with :ok <- validate_not_full(state),
         :ok <- validate_no_duplicate_players(user_id, state) do
      {:reply, :ok, %{state | users: [user_id|state.users]}}
    else
      {:error, msg} -> {:reply, {:error, msg}, state}
    end
  end

  def handle_call({:leave, user_id}, _from, state) do
    with :ok <- validate_user_joined(user_id, state) do
      {_,new_state} = {user_id, state}
      |> remove_user
      |> transfer_ownership_if_host_left

      if no_more_players?(new_state) do
        {:stop, {:shutdown, :no_more_players}, :ok, new_state}
      else
        {:reply, :ok, new_state}
      end
    else
      {:error, msg} -> {:reply, {:error, msg}, state}
    end
  end

  def handle_call(:start, _from, state) do
    {:reply, :ok, State.generate(state.users)}
  end

  def terminate(reason, state) do
    case reason do
      {:shutdown, :no_more_players} ->
        Logger.info("Game exiting [#{state.id}]: no more players")
      _ ->
        Logger.warn("Game exiting [#{state.id}]: #{reason}")
    end

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

  defp validate_no_duplicate_players(user_id, state) do
    if is_joined?(user_id, state.users) do
      {:error, :already_joined}
    else
      :ok
    end
  end

  defp validate_user_joined(user_id, state) do
    if is_joined?(user_id, state.users)do
      :ok
    else
      {:error, :not_joined}
    end
  end

  defp is_joined?(user_id, users) do
    !!Enum.find(users, false, fn stored_id -> stored_id == user_id end)
  end

  defp is_host?(user_id, state) do
    state.owner == user_id
  end

  defp no_more_players?(state) do
    Enum.count(state.users) == 0
  end

  defp transfer_ownership_if_host_left({user_id, state}) do
    if is_host?(user_id, state) do
      {user_id, %{state | owner: List.first(state.users)}}
    else
      {user_id, state}
    end
  end

  defp remove_user({user_id, state}) do
    {user_id, %{state | users: List.delete(state.users, user_id)}}
  end
end
