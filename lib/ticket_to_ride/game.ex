defmodule TicketToRide.Game do
  defstruct [
    :id,
    :owner,
    :turn_length,
    :turn_timer_ref,
    :turn_expiration_track,
    :users,
    :gamestate,
    :max_players
  ]

  use GenServer

  alias TicketToRide.State
  alias TicketToRide.Games.Index

  require Logger

  @default_timeout 30_000

  # API

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, [])
  end

  def id(game) do
    GenServer.call(game, :id, @default_timeout)
  end

  def status(game) do
    GenServer.call(game, :status, @default_timeout)
  end

  def begin(game, user_id) do
    GenServer.call(game, {:begin, user_id}, @default_timeout)
  end

  def join(game, user_id) do
    GenServer.call(game, {:join, user_id}, @default_timeout)
  end

  def leave(game, user_id) do
    GenServer.call(game, {:leave, user_id}, @default_timeout)
  end

  def action(game, user_id, payload) do
    GenServer.call(game, {:action, user_id, payload}, @default_timeout)
  end

  # Callbacks

  @default_max_players 4
  @default_min_players 2
  @default_turn_length 40_000
  @default_turn_retry_max 2

  def init(opts) do
    {:ok, %__MODULE__{
        id: UUID.uuid1(:hex),
        owner: opts[:user_id],
        users: [opts[:user_id]],
        turn_length: opts[:turn_length] || @default_turn_length,
        turn_timer_ref: nil,
        turn_expiration_track: %{},
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
        {:stop, {:shutdown, :not_enough_players}, :ok, new_state}
      else
        {:reply, :ok, new_state}
      end
    else
      {:error, msg} -> {:reply, {:error, msg}, state}
    end
  end

  def handle_call({:begin, user_id}, _from, state) do
    with true <- is_host?(user_id, state) do
      Logger.info("Game starting #{state.id}")

      new_gamestate = State.new(state.users)
      timer_ref     = trigger_turn_timer(new_gamestate, state.turn_length)
      items         = [gamestate: new_gamestate, turn_timer_ref: timer_ref]

      {:reply, :ok, merge_onto_state(state, items)}
    else
      {:error, msg} -> {:reply, {:error, msg}, state}
    end
  end

  def handle_call({:action, user_id, payload}, _from, state) do
    if user_id == state.gamestate.turn do
      new_state = state |> reset_turn_timer

      # ...
      # TODO: action dispatch
      # ...

      {:reply, :ok, new_state}
    else
      {:reply, :ok, state}
    end
  end

  def handle_info({:turn_expired, id}, state) do
    count = Map.get(state.turn_expiration_track, id)
    new_count = if count, do: count + 1, else: 1
    track = state.turn_expiration_track
    new_state = %{state | turn_expiration_track: Map.put(track, id, new_count)}

    if new_count > 2 do
      Logger.warn "Player turn expired for player #{id} on game #{state.id}"

      {_,new_state} = {id, new_state}
      |> remove_user
      |> transfer_ownership_if_host_left

      if no_more_players?(new_state) do
        {:stop, {:shutdown, :not_enough_players}, new_state}
      else
        {:noreply, reset_turn_timer(new_state)}
      end
    else
      {:noreply, reset_turn_timer(new_state)}
    end
  end

  def handle_info({:next_turn, id}, state) do
    new_gamestate = State.move_to_next_turn(state.gamestate, id)

    Logger.info "Next turn started for player #{new_gamestate.turn} on game #{state.id}"

    timer_ref = trigger_turn_timer(new_gamestate, state.turn_length)
    items     = [gamestate: new_gamestate, turn_timer_ref: timer_ref]

    {:noreply, merge_onto_state(state, items)}
  end

  def terminate(reason, state) do
    case reason do
      {:shutdown, :not_enough_players} ->
        Logger.info("Game exiting [#{state.id}]: not enough players")
      _ ->
        Logger.warn("Game exiting [#{state.id}]: #{reason |> Kernel.inspect}")
    end

    Index.remove(state.id)
  end

  # Private

  ### Turns helpers

  defp merge_onto_state(state, opts \\ []) do
    Enum.reduce(opts, state, fn ({k,v}, acc) -> Map.put(acc, k, v) end)
  end

  defp trigger_turn_timer(gamestate, turn_length) do
    Process.send_after(self(), {:turn_expired, gamestate.turn}, turn_length)
  end

  defp reset_turn_timer(state) do
    Process.cancel_timer(state.turn_timer_ref)
    Process.send(self(), {:next_turn, state.gamestate.turn}, [:noconnect])

    %{state | turn_timer_ref: nil}
  end

  ### Validations

  defp validate_enough_players(state) do
    if Enum.count(state.users) < state.min_players do
      {:error, :not_enough_players}
    else
      :ok
    end
  end

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

  ### Conditional Helpers

  defp is_joined?(user_id, users) do
    !!Enum.find(users, false, fn stored_id -> stored_id == user_id end)
  end

  defp is_host?(user_id, state) do
    state.owner == user_id
  end

  defp no_more_players?(state) do
    Enum.count(state.users) == 0
  end

  ### Utility Helpers

  defp transfer_ownership_if_host_left({user_id, state}) do
    if is_host?(user_id, state) do
      {user_id, %{state | owner: List.first(state.users)}}
    else
      {user_id, state}
    end
  end

  defp remove_user({user_id, state}) do
    players = state.gamestate.players
    index = Enum.find_index(players, &(&1.id == user_id))
    new_players = List.delete(players, index)
    new_gamestate = Map.put(state.gamestate, :players, new_players)

    new_state = state
    |> Map.put(:users, List.delete(state.users, user_id))
    |> Map.put(:gamestate, new_gamestate)

    {user_id, new_state}
  end
end
