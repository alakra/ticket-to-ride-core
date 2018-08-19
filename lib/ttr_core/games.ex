defmodule TtrCore.Games do
  @moduledoc """
  A `DynamicSupervisor` process that manages each game's process tree.
  """
  use DynamicSupervisor

  alias TtrCore.Players
  alias TtrCore.Cards
  alias TtrCore.Games.{
    Action,
    Game,
    Index,
    State
  }

  require Logger

  @type user_id :: binary()
  @type game_id :: binary()
  @type reason :: String.t
  @type game_options :: [
    owner_id: user_id()
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
  Stops the `TtrCore.Games` supervisor.
  """
  @spec stop :: :ok
  def stop do
    # TODO: Change this to DynamicSuperivsor in 1.7+
    Supervisor.stop(__MODULE__)
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
  Creates a new game process under the `TtrCore.Games` supervision
  tree and assigns the player id as the owner of the game and includes
  the owner as "joined" to the game.

  Returns `{:ok, game_id, pid}` if game succesfully created.

  Returns `{:error, :invalid_user_id}` if user id is not registered.
  """
  @spec create(user_id()) :: {:ok, game_id(), pid()} | {:error, :invalid_user_id}
  def create(user_id) do
    if Players.registered?(user_id) do
      game_id     = UUID.uuid1(:hex)
      train_deck  = Cards.shuffle_trains()
      ticket_deck = Cards.shuffle_tickets()

      state = %State{
        id: game_id,
        owner_id: user_id,
        players: [],
        train_deck: train_deck,
        ticket_deck: ticket_deck,
        displayed_trains: [],
        discard_deck: [],
        stage: :unstarted
      }

      spec = {Game, state}

      {:ok, pid} = DynamicSupervisor.start_child(__MODULE__, spec)
      {:ok, game_id, pid}
    else
      {:error, :invalid_user_id}
    end
  end

  @doc """
  Setup a game. Deals train and ticket cards to players and displays train cards.

  Returns error if game is not found.

  Returns error if the user id used is not the owner of the game.

  Returns error if the game is not in already in an unstarted stage
  (in order to move to a setup stage).
  """
  @spec setup(game_id(), user_id()) :: :ok | {:error, :not_found | :not_owner | :not_in_unstarted}
  def setup(game_id, user_id) do
    case Registry.lookup(Index, game_id) do
      [{pid, _}] ->
        Logger.info("setup game:#{game_id}")

        Game.setup(pid, user_id,
          fn train_deck, player -> Cards.deal_trains(train_deck, player, 4) end,
          fn ticket_deck, player -> Cards.deal_tickets(ticket_deck, player, 3) end,
          fn train_deck -> Enum.split(train_deck, 5) end)
      _ ->
        {:error, :not_found}
    end
  end

  @doc """
  Starts a game. Chooses a random player to start and begins the game.

  Only the user id that matches the owner of the game can start the
  game.

  If the game id does not exist, an `{:error, :not_found}` tuple is
  returned.

  If a player is used to begin a game that does not match the owner of
  the game, an `{:error, :not_owner}` tuple is returned.

  If the game has already been started, an `{:error,
  :already_started}` tuple is returned.
  """
  @spec begin(game_id(), user_id()) :: :ok | {:error, :not_found | :not_owner | :not_in_setup}
  def begin(game_id, user_id) do
    case Registry.lookup(Index, game_id) do
      [{pid, _}] ->
        Logger.info("starting game:#{game_id}")
        Game.begin(pid, user_id)
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
  @spec join(game_id(), user_id()) :: :ok |
  {:error, :not_found | :invalid_user_id | :game_full | :already_joined}
  def join(game_id, user_id) do
    if Players.registered?(user_id) do
      case Registry.lookup(Index, game_id) do
        [{pid, _}] ->
          Logger.info("user:#{user_id} joined game:#{game_id}")
          Game.join(pid, user_id)
        _ ->
          {:error, :not_found}
      end
    else
      {:error, :invalid_user_id}
    end
  end

  @doc """
  Leave a game. Returns `:ok` if successfully left.

  If the game id does not exist, an `{:error, :not_found}` tuple is
  returned.

  If the game state indicates that the user has not previously joined
  the game, then an `{:error, :not_joined}` tuple is returned.
  """
  @spec leave(game_id(), user_id()) :: :ok | {:error, :not_found | :not_joined}
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
  Performs action on turn. An `:ok` is returned on success. You must
  `get_context/2` to see your updated state.

  If the game id does not exist, an `{:error, :not_found}` tuple is
  returned.

  If the user provided in the request does not have the current turn,
  an `{:error, :not_your_turn}` tuple is returned.
  """
  @spec perform(game_id(), user_id(), Action.t) ::
    :ok | {:error, :not_found | :not_your_turn | reason()}
  def perform(game_id, user_id, action) do
    case Registry.lookup(Index, game_id) do
      [{pid, _}] ->
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
  def destroy(game_id) do
    case Registry.lookup(Index, game_id) do
      [{pid, _}] ->
        Supervisor.terminate_child(__MODULE__, pid)
      _ ->
        Logger.warn("Tried to destroy game:#{game_id}, but it doesn't exist.")
        {:error, :not_found}
    end
  end

  @doc """
  Returns contextual state based on player id in order to not reveal
  secrets to others for a particular game.
  """
  @spec get_context(game_id(), user_id()) :: {:ok, Context.t} | {:error, :not_found | :not_joined}
  def get_context(game_id, user_id) do
    case Registry.lookup(Index, game_id) do
      [{pid, _}] -> Game.get_context(pid, user_id)
        _ -> {:error, :not_found}
    end
  end

  @doc """
  Returns complete game state.
  """
  @spec get_state(game_id()) :: {:ok, State.t} | {:error, :not_found}
  def get_state(game_id) do
    case Registry.lookup(Index, game_id) do
      [{pid, _}] -> {:ok, Game.get_state(pid)}
        _ -> {:error, :not_found}
    end
  end

  # Callbacks

  @impl true
  def init(_args) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end
end