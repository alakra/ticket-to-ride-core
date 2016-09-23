defmodule TicketToRide.Game do
  use GenServer

  alias TicketToRide.Game.{Index, Machine, Turns}

  require Logger

  @default_timeout 30_000
  @max_players 4

  # API

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, [])
  end

  def begin(game, player_id) do
    GenServer.call(game, {:begin, player_id}, @default_timeout)
  end

  def join(game, player_id) do
    GenServer.call(game, {:join, player_id}, @default_timeout)
  end

  def leave(game, player_id) do
    GenServer.call(game, {:leave, player_id}, @default_timeout)
  end

  def finish(game, player_id) do
    GenServer.call(game, {:finish, player_id}, @default_timeout)
  end

  def action(game, player_id, payload) do
    GenServer.call(game, {:action, player_id, payload}, @default_timeout)
  end

  # Callbacks

  def init(opts) do
    {:ok, machine} = Machine.start_link(owner: opts[:owner_id])
    {:ok, turns}   = Turns.start_link(machine: machine)

    {:ok, %{id: opts[:id], turns: turns, machine: machine}}
  end

  def handle_call({:join, player_id}, _from, %{machine: machine} = state) do
    players = Machine.get(machine, :players)

    with :ok <- validate_not_full(players),
         :ok <- validate_no_duplicate_players(players, player_id) do
      Machine.add_player(machine, player_id)
      {:reply, :ok, state}
    else
      {:error, msg} -> {:reply, {:error, msg}, state}
    end
  end

  def handle_call({:leave, player_id}, _from, %{machine: machine} = state) do
    players = Machine.get(machine, :players)

    with :ok <- validate_player_joined(players, player_id) do
      Machine.remove_player(machine, player_id)

      if Machine.get(machine, :players) |> no_more_players? do
        {:stop, {:shutdown, :not_enough_players}, :ok, state}
      else
        {:reply, :ok, state}
      end
    else
      {:error, msg} -> {:reply, {:error, msg}, state}
    end
  end

  def handle_call({:begin, player_id}, _from, state) do
    owner   = Machine.get(state.machine, :owner)
    players = Machine.get(state.machine, :players)

    with true <- owner == player_id do
      {:ok, _} = Machine.generate(state.machine)
      Turns.begin(state.turns, players)

      {:reply, :ok, state}
    else
      _ ->
        Logger.warn("#{player_id} is trying to start a game, but is not the owner (#{owner}) of game ##{state.id}")
        {:reply, {:error, :cannot_start_game}, state}
    end
  end

  def handle_call({:action, player_id, payload}, _from, state) do
    current_player = Turns.current(state.turns)

    if player_id == current_player.id do
      # ...
      # TODO: action dispatch
      # ...
    else
      Logger.warn("Ignoring player #{player_id} because it's not his turn.")
    end

    {:reply, :ok, state}
  end

  def handle_call({:finish, player_id}, _from, state) do
    current_player = Turns.current(state.turns)

    if player_id == current_player.id do
      Turns.finish(state.turns)
    else
      Logger.warn("Ignoring player #{player_id} because it's not his turn.")
    end

    {:reply, :ok, state}
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

  ### Validations

  defp validate_not_full(players) do
    if Enum.count(players) <= @max_players do
      :ok
    else
      {:error, :full}
    end
  end

  defp validate_no_duplicate_players(players, player_id) do
    if is_joined?(players, player_id) do
      {:error, :already_joined}
    else
      :ok
    end
  end

  defp validate_player_joined(players, player_id) do
    if is_joined?(players, player_id)do
      :ok
    else
      {:error, :not_joined}
    end
  end

  ### Conditional Helpers

  defp is_joined?(players, player_id) do
    Enum.any?(players, fn stored_id -> stored_id == player_id end)
  end

  defp no_more_players?(players) do
    Enum.count(players) == 0
  end
end
