defmodule TtrCore.Players do
  @moduledoc """
  Functions for registering and authenticating players.
  """

  use Supervisor

  alias TtrCore.Players.{
    DB,
    Player,
    Session,
    User
  }

  @type user_id() :: Session.user_id()
  @type username() :: String.t
  @type password() :: binary()

  @doc """
  Starts player supervision tree.
  """
  def start_link do
    Supervisor.start_link(__MODULE__, [], [name: __MODULE__])
  end

  @doc """
  Stops player supervision tree.
  """
  @spec stop :: :ok
  def stop do
    Supervisor.stop(__MODULE__)
  end

  @doc """
  Specifies `TtrCore.Players` to run as a supervisor.
  """
  @spec child_spec(term) :: Supervisor.child_spec()
  def child_spec(_) do
    %{id: __MODULE__,
      start: {__MODULE__, :start_link, []},
      type: :supervisor}
  end

  @doc """
  Adds a player to a list of players with only a user id.
  """
  @spec add_player([Player.t], user_id()) :: [Player.t]
  def add_player(players, id) do
    [%Player{id: id} | players]
  end

  @doc """
  Checks to see if any players are out of stock (2 or less trains)
  """
  @spec any_out_of_stock?([Player.t]) :: boolean()
  def any_out_of_stock?(players) do
    Enum.any?(players, fn player -> Player.out_of_stock?(player) end)
  end

  @doc """
  Finds a player from a list of players by id.
  """
  @spec find_by_id([Player.t], user_id()) :: Player.t
  def find_by_id(players, user_id) do
    Enum.find(players, fn %{id: id} -> id == user_id end)
  end

  @doc """
  Get all active users (those who are logged in with non-expired
  sessions).
  """
  @spec get_active_users() :: [User.t]
  def get_active_users() do
    fn session -> session.user_id end
    |> Session.find_active()
    |> DB.find_users()
  end

  @doc """
  Checks to see if a player has a set of tickets in their buffer.
  """
  @spec has_tickets?(Player.t, [TicketCard.t]) :: boolean()
  def has_tickets?(%{tickets_buffer: buffer}, tickets) do
    Enum.all?(tickets, fn ticket -> Enum.member?(buffer, ticket) end)
  end

  @doc """
  Selects a random player from a list of players.
  """
  @spec select_random_player([Player.t]) :: Player.t
  def select_random_player(players) do
    Enum.random(players)
  end

  @doc """
  Checks to see if user id is registered.
  """
  @spec registered?(user_id()) :: boolean()
  def registered?(user_id), do: DB.find_users([user_id]) != []

  @doc """
  Remove a player from a list of players.
  """
  @spec remove_player([Player.t], user_id()) :: [Player.t]
  def remove_player(players, user_id) do
    index = Enum.find_index(players, &(&1.id == user_id))
    List.delete_at(players, index)
  end

  @doc """
  Replace an updated player in a list of players. Finds a player by
  id, replaces the struct and returns the updated list.
  """
  @spec replace_player([Player.t], Player.t) :: [Player.t]
  def replace_player(players, %{id: id} = player) do
    index = Enum.find_index(players, fn player -> player.id == id end)
    List.replace_at(players, index, player)
  end

  @doc """
  Registers username with password into the player database.  Returns
  the user id.

  If the user already exists, then an `{:error, :already_registered}`
  tuple is returned.

  NOTE: This is not currently persistent between restarts.
  """
  @spec register(username(), password()) :: {:ok, user_id()} | {:error, :already_registered}
  defdelegate register(username, password), to: DB

  @doc """
  Login a user. Returns a token that is used to track a user's
  relationship to a game.
  """
  @spec login(username(), password()) :: {:ok, Session.t} | {:error, :user_not_found | :incorrect_password}
  defdelegate login(username, password), to: Session, as: :create

  @doc """
  Logout a user. Returns `:ok`
  """
  @spec logout(user_id()) :: :ok
  defdelegate logout(user_id), to: Session, as: :destroy

  @doc """
  Get all users.
  """
  @spec get_users() :: [User.t]
  defdelegate get_users(), to: DB, as: :get_all_users

  @doc """
  Add tickets to player
  """
  @spec add_tickets(Player.t, [TicketCard.t]) :: Player.t
  defdelegate add_tickets(player, tickets), to: Player

  @doc """
  Add tickets to player's buffer
  """
  @spec add_tickets_to_buffer(Player.t, [TicketCard.t]) :: Player.t
  defdelegate add_tickets_to_buffer(player, tickets), to: Player

  @doc """
  Add trains to player
  """
  @spec add_trains(Player.t, [TicketCard.t]) :: Player.t
  defdelegate add_trains(player, tickets), to: Player

  @doc """
  Add trains to player on turn
  """
  @spec add_trains_on_turn(Player.t, [TicketCard.t]) :: Player.t
  defdelegate add_trains_on_turn(player, tickets), to: Player

  @doc """
  Add route to player with cost
  """
  @spec add_route(Player.t, Route.t, integer()) :: Player.t
  defdelegate add_route(player, route, count), to: Player

  @doc """
  Remove specific number of trains from player
  """
  @spec remove_trains(Player.t, TrainCard.t, integer()) :: Player.t
  defdelegate remove_trains(player, train, count), to: Player

  @doc """
  Remove tickets from player's buffer. Looks at the passed in
  tickets and returns anything not in that list of cards that remains
  in the ticket buffer.
  """
  @spec remove_tickets_from_buffer(Player.t, [TicketCard.t]) :: {Player.t, [TicketCard.t]}
  defdelegate remove_tickets_from_buffer(player, tickets), to: Player

  @doc """
  Reset player's selections (trains, tickets, etc.)
  """
  @spec reset_selections(Player.t) :: Player.t
  defdelegate reset_selections(player), to: Player

  # Callbacks

  @impl true
  def init(_args) do
    children = [
      DB,
      Session
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
