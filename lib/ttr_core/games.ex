defmodule TtrCore.Games do
  @moduledoc """
  A `DynamicSupervisor` process that manages each game's process tree.
  """
  use DynamicSupervisor

  alias TtrCore.Games.{
    Game,
    Index,
    Options,
    Result
  }

  require Logger

  @type player_id :: binary()
  @type game_id :: binary()

  @type reason :: String.t
  @type game_options :: [
    owner_id: player_id()
  ]

  # API

  @doc """
  Starts the `TtrCore.Games` supervisor.
  """
  @spec start_link :: {:ok, pid()}
  def start_link do
    DynamicSupervisor.start_link(__MODULE__, [], [name: __MODULE__])
  end

  @doc """
  Specifies `TtrCore.Games` to run as a supervisor.
  """
  @spec child_spec(term) :: Supervisor.child_spec()
  def child_spec(_) do
    %{id: __MODULE__,
      start: {__MODULE__, :start_link, []},
      type: :supervisor}
  end

  @doc """
  Get list of all Game IDs. Not ordered.
  """
  @spec list() :: {:ok, [game_id()]}
  def list do
    ids = __MODULE__
    |> DynamicSupervisor.which_children()
    |> Enum.flat_map(fn {_, pid, _, _} -> Registry.keys(Index, pid) end)

    {:ok, ids}
  end

  @doc """
  Creates a new game process under the `TtrCore.Games` supervision
  tree and assigns the player id as the owner of the game.

  Returns `{:ok, game_id, pid}` if game succesfully created.

  If there is an error, an `{:error, reason}` tuple is returned.
  """
  @spec create(player_id()) :: {:ok, game_id(), pid()} | {:error, reason()}
  def create(player_id) do
    opts = %Options{id: UUID.uuid1(:hex), owner_id: player_id}
    spec = {Game, opts}

    {:ok, pid} = DynamicSupervisor.start_child(__MODULE__, spec)
    {:ok, opts.id, pid}
  end

  @doc """
  Starts a game.

  Only the player id that matches the owner of the game can start the
  game.

  If the game id does not exist, an `{:error, :not_found}` tuple is
  returned.

  If a player is used to begin a game that does not match the owner of
  the game, an `{:error, :not_owner}` tuple is returned.

  If the game has already been started, an `{:error,
  :already_started}` tuple is returned.
  """
  @spec begin(game_id(), player_id()) :: :ok | {:error, :not_found | :not_owner | :already_started}
  def begin(game_id, player_id) do
    case Registry.lookup(Index, game_id) do
      [{pid, _}] ->
        Logger.info("Starting game:#{game_id}")
        Game.begin(pid, player_id)
      _ ->
        {:error, :not_found}
    end
  end

  @doc """
  Join a game. Returns `:ok` if successfully joined.

  If the game id does not exist, an `{:error, :not_found}` tuple is
  returned.

  If the game state indicates that the game is full, an `{:error,
  :game_full}` tuple is returned.

  If the game state shows that the player being added already exists
  in ithe game, an `{:error, :already_joined}` tuple is returned.
  """
  @spec join(game_id(), player_id()) :: :ok | {:error, :not_found | :game_full | :already_joined}
  def join(game_id, user_id) do
    case Registry.lookup(Index, game_id) do
      [{pid, _}] ->
        Logger.info("user:#{user_id} joined game:#{game_id}")
        Game.join(pid, user_id)
      _ ->
        {:error, :not_found}
    end
  end

  @doc """
  Leave a game. Returns `:ok` if successfully left.

  If the game id does not exist, an `{:error, :not_found}` tuple is
  returned.

  If the game state indicates that the user has not previously joined
  the game, then an `{:error, :not_joined}` tuple is returned.
  """
  @spec leave(game_id(), player_id()) :: :ok | {:error, :not_found | :not_joined}
  def leave(game_id, user_id) do
    case Registry.lookup(Index, game_id) do
      [{pid, _}] ->
        Logger.info("user:#{user_id} left game:#{game_id}")
        Game.leave(pid, user_id)
      _ ->
        {:error, :not_found}
    end
  end

  @doc """
  Performs action on turn. An `:ok` or `{:ok, result}` is
  returned on success. The `Result` is a datastructure that can be
  used to update the current player's view of the game.

  If the game id does not exist, an `{:error, :not_found}` tuple is
  returned.

  If the user provided in the request does not have the current turn,
  an `{:error, :not_your_turn}` tuple is returned.
  """
  @spec perform(game_id(), player_id(), Action.t) ::
    :ok | {:ok, Result.t} | {:error, :not_found | :not_your_turn | reason()}
  def perform(game_id, user_id, action) do
    case Registry.lookup(Index, game_id) do
      [{pid, _}] ->
        Logger.info("user:#{user_id} performs action:#{inspect(action)} on game:#{game_id}")
        Game.perform(pid, user_id, action)
      _ ->
        {:error, :not_found}
    end
  end

  @doc """
  End a game. Returns `:ok` if successfully ended.

  If the game id does not exist, an `{:error, :not_found}` tuple is
  returned.
  """
  @spec destroy(game_id()) :: :ok | {:error, :not_found}
  def destroy(game) do
    case Supervisor.terminate_child(__MODULE__, game) do
      :ok -> :ok
      {:error, :not_found} ->
        Logger.warn("Tried to destroy game:#{game}, but it doesn't exist.")
        :ok
    end
  end

  # Callbacks

  @impl true
  def init(_args) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end
end
