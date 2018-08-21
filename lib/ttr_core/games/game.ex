defmodule TtrCore.Games.Game do
  @moduledoc false

  use GenServer

  alias TtrCore.Games.{
    Action,
    Index,
    Ticker,
    Turns
  }

  alias TtrCore.Mechanics
  alias TtrCore.Mechanics.State
  alias TtrCore.Players.User

  require Logger

  @type reason :: binary()
  @type game() :: pid()
  @type id :: binary()

  @default_timeout 30_000

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
    GenServer.call(game, {:setup, user_id}, @default_timeout)
  end

  @spec begin(game(), User.id) ::
  :ok | {:error, :not_owner | :not_enough_players | :not_in_setup | :tickets_not_selected}
  def begin(game, user_id) do
    GenServer.call(game, {:begin, user_id}, @default_timeout)
  end

  @spec join(game(), User.id) :: :ok | {:error, :game_full | :already_joined}
  def join(game, user_id) do
    GenServer.call(game, {:join, user_id}, @default_timeout)
  end

  @spec leave(game(), User.id) :: :ok | {:error, :not_joined}
  def leave(game, user_id) do
    GenServer.call(game, {:leave, user_id}, @default_timeout)
  end

  @spec perform(game(), User.id, Action.t) :: :ok | {:error, reason()}
  def perform(game, user_id, action) do
    GenServer.call(game, {:perform, user_id, action}, @default_timeout)
  end

  @spec force_end_turn(game()) :: :ok
  def force_end_turn(game) do
    GenServer.cast(game, :force_end_turn)
  end

  @spec get_context(game(), User.id) :: {:ok, Context.t} | {:error, :not_joined}
  def get_context(game, user_id) do
    GenServer.call(game, {:get, :context, user_id}, @default_timeout)
  end

  @spec get_state(game()) :: State.t
  def get_state(game) do
    GenServer.call(game, {:get, :state}, @default_timeout)
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
    case Mechanics.is_joined?(state, user_id) do
      :ok ->
        state
        |> Mechanics.remove_player(user_id)
        |> stop_if_no_more_players
      {:error, reason} ->
        {:reply, {:error, reason}, state}
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

  def handle_call({:perform, user_id, {:select_tickets, tickets}}, _from, state) do
    case Mechanics.select_tickets(state, user_id, tickets) do
      {:ok, new_state} -> {:reply, :ok, new_state}
      {:error, reason} -> {:reply, {:error, reason}, state}
    end
  end

  def handle_call({:perform, user_id, :draw_tickets}, _from, state) do
    {:reply, :ok, Mechanics.draw_tickets(state, user_id)}
  end

  def handle_call({:perform, user_id, {:select_trains, trains}}, _from, state) do
    case Mechanics.select_trains(state, user_id, trains) do
      {:ok, new_state} -> {:reply, :ok, new_state}
      {:error, reason} -> {:reply, {:error, reason}, state}
    end
  end

  def handle_call({:perform, user_id, {:draw_trains, count}}, _from, state) do
    {:ok, new_state} = Mechanics.draw_trains(state, user_id, count)
    {:reply, :ok, new_state}
  end

  def handle_call({:perform, user_id, {:claim_route, route, train_card, cost}}, _from, state) do
    case Mechanics.claim_route(state, user_id, route, train_card, cost) do
      {:ok, new_state} -> {:reply, :ok, new_state}
      {:error, reason} -> {:reply, {:error, reason}, state}
    end
  end

  def handle_call({:perform, user_id, :end_turn}, _from, state) do
    case Mechanics.end_turn(state, user_id) do
      {:ok, new_state} -> {:reply, :ok, new_state}
      {:error, reason} -> {:reply, {:error, reason}, state}
    end
  end

  def handle_call({:get, :context, user_id}, _from, state) do
    case Mechanics.is_joined?(state, user_id) do
      :ok ->
        {:reply, {:ok, Mechanics.generate_context(state, user_id)}, state}
      {:error, reason} ->
        {:reply, {:error, reason}, state}
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
