defmodule TtrCore.Games.Game do
  @moduledoc """
  A `GenServer` process that manages the process tree of a single
  game and handles joining, beginning, leaving, and finishing a game.

  It forwards all other game actions onto `TtrCore.Game.Machine` and
  `TtrCore.Game.Turns`.

  ## Notes

  This is not intended to be used directly unless debugging is
  necessary. See `TtrCore.Games` for intended interface (documentation
  for this module may eventually be removed to prevent confusion).
  """
  use GenServer

  alias TtrCore.Games.{
    Index,
    Machine,
    Options,
    State,
    Ticker,
    Turns
  }

  require Logger

  @type reason :: binary()
  @type player_id :: binary()
  @type game() :: pid()
  @type id :: binary()

  @default_timeout 30_000

  # API

  @doc """
  Starts the `TtrCore.Game` process.
  """
  @spec start_link(Options.t) :: {:ok, pid()}
  def start_link(%Options{id: id} = opts) do
    name = {:via, Registry, {Index, id}}
    GenServer.start_link(__MODULE__, opts, name: name)
  end

  @doc """
  Specifies `TtrCore.Game` to run as a worker.
  """
  @spec child_spec(Options.t) :: Supervisor.child_spec()
  def child_spec(opts) do
    %{id: __MODULE__,
      start: {__MODULE__, :start_link, [opts]},
      restart: :transient,
      type: :worker}
  end

  @doc """
  Begins a game.

  Only the owner of the game can start a game.

  If the player id is not the owner of game, then an `{:error,
  :not_owner}` tuple is returned.

  If the game has already been started, then an `{:error,
  :already_started}` tuple is returned.
  """
  @spec begin(game(), player_id()) :: :ok | {:error, :not_owner | :already_started}
  def begin(game, player_id) do
    GenServer.call(game, {:begin, player_id}, @default_timeout)
  end

  @doc """
  Join a game. Returns `:ok` if successfully joined.

  If the game state indicates that the game is full, an `{:error,
  :game_full}` tuple is returned.

  If the game state shows that the player being added already exists
  in ithe game, an `{:error, :already_joined}` tuple is returned.
  """
  @spec join(game(), player_id()) :: :ok | {:error, :game_full | :already_joined}
  def join(game, player_id) do
    GenServer.call(game, {:join, player_id}, @default_timeout)
  end

  @doc """
  Leave a game. Returns `:ok` if left successfully left.

  If the game state indicates that the user has not previously joined
  the game, then an `{:error, :not_joined}` tuple is returned.
  """
  @spec leave(game(), player_id()) :: :ok | {:error, :not_joined}
  def leave(game, player_id) do
    GenServer.call(game, {:leave, player_id}, @default_timeout)
  end

  @doc """
  Performs action on turn.
  """
  @spec perform(game(), player_id(), Action.t) :: :ok | {:error, reason()}
  def perform(game, player_id, action) do
    GenServer.call(game, {:perform, player_id, action}, @default_timeout)
  end

  @doc """
  Force next turn on game state. Utilized by internal timing
  system. Can be used for debug purposes also.
  """
  @spec force_next_turn(game()) :: :ok
  def force_next_turn(game) do
    GenServer.cast(game, :force_next_turn)
  end

  # Callbacks

  def init(%Options{id: id, owner_id: owner_id}) do
    state = %State{}
    |> Map.put(:id, id)
    |> Map.put(:owner_id, owner_id)
    |> Machine.add_player(owner_id)

    {:ok, state}
  end

  def handle_call({:join, player_id}, _from, state) do
    case Machine.can_join?(state, player_id) do
      :ok -> {:reply, :ok, Machine.add_player(state, player_id)}
      {:error, reason} -> {:reply, {:error, reason}, state}
    end
  end

  def handle_call({:leave, player_id}, _from, state) do
    case Machine.can_leave?(state, player_id) do
      :ok ->
        state
        |> Machine.remove_player(player_id)
        |> stop_if_no_more_players
      {:error, reason} ->
        {:reply, {:error, reason}, state}
    end
  end

  def handle_call({:begin, player_id}, _from, state) do
    case Machine.can_begin?(state, player_id) do
      :ok ->
        {:ok, new_state} = Machine.begin_game(state)
        start_tick = Ticker.get_new_start_tick()

        Registry.register(Turns, :turns, {new_state.id, start_tick})

        {:reply, :ok, new_state}
      {:error, reason} ->
        {:reply, {:error, reason}, state}
    end
  end

  def handle_call({:perform, player_id, action}, _from, %{current_player: current_player} = state) do
    if player_id == current_player.id do
      # ...
      # TODO: action dispatch
      # ...
    else
      Logger.warn("Ignoring player #{player_id} because it's not his turn.")
    end

    {:reply, :ok, state}
  end

  def handle_cast(:force_next_turn, %{current_player: player} = state) do
    {:noreply, Machine.perform(state, {:force_end_turn, player})}
  end

  def terminate(reason, state) do
    case reason do
      {:shutdown, :not_enough_players} ->
        Logger.info("Game exiting [#{state.id}]: not enough players")
      _ ->
        Logger.warn("Game exiting [#{state.id}]: #{reason |> Kernel.inspect}")
    end
  end

  # Private

  defp stop_if_no_more_players(%{players: players} = state) do
    if Enum.empty?(players) do
      {:stop, {:shutdown, :not_enough_players}, :ok, state}
    else
      {:reply, :ok, state}
    end
  end
end
