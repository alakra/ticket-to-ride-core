defmodule TtrCore.Games.Machine do
  alias TtrCore.Player
  alias TtrCore.Games.State

  @type player_id :: binary()
  @max_players 4

  # API

  @doc """
  Returns `:ok` if the game can be started.

  If the game state indicates that it has already been started, an
  `{:error, :already_started}` tuple is returned.

  If the game state indicates that the player trying to start the game
  is not the owner, an `{:error, :not_owner}` tuple is returned.

  If the game does not have at least 2 players, an `{:error,
  :not_enough_players}` tuple is returned.
  """
  @spec can_begin?(State.t, player_id()) :: :ok |
    {:error, :already_started | :not_owner | :not_enough_players}
  def can_begin?(%{owner_id: owner_id, players: players} = state, player_id) do
    result = []
    |> validate_owner(owner_id, player_id)
    |> validate_enough_players(players)
    |> validate_game_not_started(state)

    case result do
      [error|_] -> error
      _ -> :ok
    end
  end

  @doc """
  Returns `:ok` if a player can be added to a game.

  If the game state indicates that the game is full, an `{:error,
  :game_full}` tuple is returned.

  If the game state shows that the player being added already exists
  in ithe game, an `{:error, :already_joined}` tuple is returned.
  """
  @spec can_join?(State.t, player_id()) :: :ok | {:error, :game_full | :already_joined}
  def can_join?(%{players: players}, player_id) do
    result = []
    |> validate_not_full(players)
    |> validate_no_duplicate_players(players, player_id)

    case result do
      [error|_] -> error
      _ -> :ok
    end
  end

  @doc """
  Returns `:ok` if a player can leave a game.

  If the player has not already joined a game, an `{:error,
  :not_joined}` tuple is returned.
  """
  @spec can_leave?(State.t, player_id()) :: :ok | {:error, :not_joined}
  def can_leave?(%{players: players}, player_id) do
    case validate_player_joined([], players, player_id) do
      [error|_] -> error
      _ -> :ok
    end
  end

  @doc """
  Returns a new game state that has been started and registers game id
  to turn tracking ticker.
  """
  @spec begin_game(State.t) :: State.t
  def begin_game(state), do: State.new(state)

  @doc """
  Adds a new player to the state.
  """
  @spec add_player(State.t, player_id()) :: State.t
  def add_player(state, player_id) do
    %{state | players: [%Player{id: player_id} | state.players]}
  end

  @doc """
  Removes a player from the state.
  """
  @spec remove_player(State.t, player_id()) :: State.t
  def remove_player(state, player_id) do
    index = Enum.find_index(state.players, &(&1.id == player_id))
    new_players = List.delete_at(state.players, index)

    %{state | players: new_players}
    |> transfer_ownership_if_host_left
  end

  @spec perform(State.t, Action.t) :: :ok
  def perform(state, action) do
    # TBD
  end

  # Private

  defp transfer_ownership_if_host_left(state) do
    result = Enum.any?(state.players, fn player -> player.id == state.owner_id end)

    if result do
      %{state | owner_id: List.first(state.players).id}
    else
      state
    end
  end

  defp validate_owner(errors, owner_id, player_id) do
    if owner_id == player_id do
      errors
    else
      [{:error, :not_owner} | errors]
    end
  end

  defp validate_enough_players(errors, players) do
    if Enum.count(players) > 1 do
      errors
    else
      [{:error, :not_enough_players} | errors]
    end
  end

  defp validate_game_not_started(errors, state) do
    if not state.started? do
      errors
    else
      [{:error, :already_started} | errors]
    end
  end

  defp validate_not_full(errors, players) do
    if Enum.count(players) <= @max_players do
      errors
    else
      [{:error, :game_full} | errors]
    end
  end

  defp validate_no_duplicate_players(errors, players, player_id) do
    if is_joined?(players, player_id) do
      [{:error, :already_joined} | errors]
    else
      errors
    end
  end

  defp validate_player_joined(errors, players, player_id) do
    if is_joined?(players, player_id) do
      errors
    else
      [{:error, :not_joined} | errors]
    end
  end

  defp is_joined?(players, player_id) do
    Enum.any?(players, fn %Player{id: stored_id} -> stored_id == player_id end)
  end
end
