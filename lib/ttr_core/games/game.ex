defmodule TtrCore.Games.Game do
  @moduledoc false

  use GenServer

  alias TtrCore.Cards.{
    TicketCard,
    TrainCard
  }

  alias TtrCore.Games.{
    Index,
    Ticker,
    Turns
  }

  alias TtrCore.Mechanics
  alias TtrCore.Mechanics.{
    Context,
    State
  }

  alias TtrCore.Players.User

  require Logger

  @type reason :: binary()
  @type game() :: pid()
  @type id :: binary()

  # API

  @spec start_link(State.t) :: GenServer.on_start()
  def start_link(%State{id: id} = state) do
    name = {:via, Registry, {Index, id}}
    GenServer.start_link(__MODULE__, state, name: name)
  end

  @spec child_spec(State.t) :: Supervisor.child_spec()
  def child_spec(state) do
    %{id: __MODULE__,
      start: {__MODULE__, :start_link, [state]},
      restart: :transient,
      type: :worker}
  end

  @spec setup(game(), User.id) ::
  :ok | {:error, :not_owner | :not_enough_players | :not_in_unstarted}
  def setup(game, user_id) do
    GenServer.call(game, {:setup, user_id})
  end

  @spec begin(game(), User.id) ::
  :ok | {:error, :not_owner | :not_enough_players | :not_in_setup | :tickets_not_selected}
  def begin(game, user_id) do
    GenServer.call(game, {:begin, user_id})
  end

  @spec join(game(), User.id) :: :ok | {:error, :game_full | :already_joined}
  def join(game, user_id) do
    GenServer.call(game, {:join, user_id})
  end

  @spec leave(game(), User.id) :: :ok | {:error, :not_joined}
  def leave(game, user_id) do
    GenServer.call(game, {:leave, user_id})
  end

  @spec select_tickets(game(), User.id, [TicketCard.t]) :: :ok | {:error, reason()}
  def select_tickets(game, user_id, tickets) do
    GenServer.call(game, {:select_tickets, user_id, tickets})
  end

  @spec draw_tickets(game(), User.id) :: :ok
  def draw_tickets(game, user_id) do
    GenServer.call(game, {:draw_tickets, user_id})
  end

  @spec select_trains(game(), User.id, [TrainCard.t]) :: :ok | {:error, reason()}
  def select_trains(game, user_id, trains) do
    GenServer.call(game, {:select_trains, user_id, trains})
  end

  @spec draw_trains(game(), User.id, integer()) :: :ok | {:error, reason()}
  def draw_trains(game, user_id, count) do
    GenServer.call(game, {:draw_trains, user_id, count})
  end

  @spec claim_route(game(), User.id, Route.t, [TrainCard.t]) :: :ok | {:error, reason()}
  def claim_route(game, user_id, route, train_cards) do
    GenServer.call(game, {:claim_route, user_id, route, train_cards})
  end

  @spec end_turn(game(), User.id) :: :ok | {:error, reason}
  def end_turn(game, user_id) do
    GenServer.call(game, {:end_turn, user_id})
  end

  @spec force_end_turn(game()) :: :ok
  def force_end_turn(game) do
    GenServer.cast(game, :force_end_turn)
  end

  @spec get_context(game(), User.id) :: {:ok, Context.t} | {:error, :not_joined | :user_not_found}
  def get_context(game, user_id) do
    GenServer.call(game, {:get, :context, user_id})
  end

  @spec get_state(game()) :: State.t
  def get_state(game) do
    GenServer.call(game, {:get, :state})
  end

  # Callbacks

  def init(%{owner_id: owner_id} = state) do
    {:ok, Mechanics.add_player(state, owner_id)}
  end

  def handle_call({:join, user_id}, _from, state) do
    case Mechanics.can_join?(state, user_id) do
      :ok -> {:reply, :ok, Mechanics.add_player(state, user_id)}
      {:error, reason} -> {:reply, {:error, reason}, state}
    end
  end

  def handle_call({:leave, user_id}, _from, state) do
    if Mechanics.is_joined?(state, user_id) do
      state
      |> Mechanics.remove_player(user_id)
      |> stop_if_no_more_players
    else
      {:reply, {:error, :not_joined}, state}
    end
  end

  def handle_call({:setup, user_id}, _from, state) do
    case Mechanics.can_setup?(state, user_id) do
      :ok ->
        {:reply, :ok, Mechanics.setup_game(state)}
      {:error, reason} ->
        {:reply, {:error, reason}, state}
    end
  end

  def handle_call({:begin, user_id}, _from, %{id: game_id} = state) do
    case Mechanics.can_begin?(state, user_id) do
      :ok ->
        start_tick = Ticker.get_new_start_tick()
        Registry.register(Turns, :turns, {game_id, start_tick})

        {:reply, :ok, Mechanics.start_game(state)}
      {:error, reason} ->
        {:reply, {:error, reason}, state}
    end
  end

  def handle_call({:select_tickets, user_id, tickets}, _from, state) do
    case Mechanics.select_tickets(state, user_id, tickets) do
      {:ok, new_state} -> {:reply, :ok, new_state}
      {:error, reason} -> {:reply, {:error, reason}, state}
    end
  end

  def handle_call({:draw_tickets, user_id}, _from, state) do
    {:ok, state} = Mechanics.draw_tickets(state, user_id)
    {:reply, :ok, state}
  end

  def handle_call({:select_trains, user_id, trains}, _from, state) do
    case Mechanics.select_trains(state, user_id, trains) do
      {:ok, new_state} -> {:reply, :ok, new_state}
      {:error, reason} -> {:reply, {:error, reason}, state}
    end
  end

  def handle_call({:draw_trains, user_id, count}, _from, state) do
    {:ok, new_state} = Mechanics.draw_trains(state, user_id, count)
    {:reply, :ok, new_state}
  end

  def handle_call({:claim_route, user_id, route, train_cards}, _from, state) do
    case Mechanics.claim_route(state, user_id, route, train_cards) do
      {:ok, new_state} -> {:reply, :ok, new_state}
      {:error, reason} -> {:reply, {:error, reason}, state}
    end
  end

  def handle_call({:end_turn, user_id}, _from, state) do
    case Mechanics.end_turn(state, user_id) do
      {:ok, new_state} -> {:reply, :ok, new_state}
      {:error, reason} -> {:reply, {:error, reason}, state}
    end
  end

  def handle_call({:get, :context, user_id}, _from, state) do
    if Mechanics.is_joined?(state, user_id) do
      case Mechanics.generate_context(state, user_id) do
        {:ok, context}   -> {:reply, {:ok, context}, state}
        {:error, reason} -> {:reply, {:error, reason}, state}
      end
    else
      {:reply, {:error, :not_joined}, state}
    end
  end

  def handle_call({:get, :state}, _from, state) do
    {:reply, state, state}
  end

  def handle_cast(:force_end_turn, state) do
    {:noreply, Mechanics.force_end_turn(state)}
  end

  def terminate(reason, state) do
    case reason do
      {:shutdown, :not_enough_players} ->
        Logger.info("Game exiting [#{state.id}]: not enough players")
      _ ->
        Logger.warn("Game exiting [#{state.id}]: #{Kernel.inspect(reason)}")
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
