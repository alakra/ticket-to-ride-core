defmodule TicketToRide.Game.Turns do
  @default_length 30_000
  @default_max_retries 2

  defstruct [
    id: nil,
    max_retries: @default_max_retries,
    length: @default_length,
    timer: nil,
    machine: nil,
    expirations: %{},
    players: [],
    current: nil
  ]

  use GenServer

  require Logger

  alias TicketToRide.Game.Machine

  # API

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, [])
  end

  def current(pid) do
    GenServer.call(pid, :current)
  end

  def begin(pid, players) do
    GenServer.cast(pid, {:begin, players})
  end

  def finish(pid) do
    GenServer.cast(pid, :finish)
  end

  # Callbacks

  def init(opts) do
    {:ok, %__MODULE__{id: opts[:id], machine: opts[:machine]}}
  end

  def handle_call(:current, _from, state) do
    {:reply, state.current, state}
  end

  def handle_cast({:begin, players}, state) do
    first_player = List.first(players)
    timer = Process.send_after(self(), {:expired, first_player}, state.length)

    new_state = state
    |> Map.put(:timer, timer)
    |> Map.put(:players, players)
    |> Map.put(:current, first_player)

    {:noreply, new_state}
  end

  def handle_cast(:finish, state) do
    new_state = state.current
    |> next_player(state)
    |> reset_turn_timer(state)

    {:noreply, new_state}
  end

  def handle_info({:expired, previous_player}, state) do
    Logger.warn "Player turn expired for player #{previous_player} on game #{state.id}"

    {new_state, new_count} = strike_player(previous_player, state)
    next_player = next_player(previous_player, new_state.players)

    if new_count > 2 do
      new_state = remove_player(previous_player, new_state)

      if Enum.count(new_state.players) == 0 do
        Logger.info("Shutting down game ##{state.id} due to no more players.")
        {:stop, {:shutdown, :not_enough_players}, new_state}
      else
        {:noreply, reset_turn_timer(next_player, new_state)}
      end
    else
      {:noreply, reset_turn_timer(next_player, new_state)}
    end
  end

  def handle_info({:next, next_player}, state) do
    timer = Process.send_after(self(), {:expired, next_player}, state.length)

    new_state = state
    |> Map.put(:timer, timer)
    |> Map.put(:current, next_player)

    Logger.info "Next turn started for player #{new_state.current} on game #{state.id}"

    {:noreply, new_state}
  end

  # Private

  defp next_player(previous_player, players) do
    next_index = Enum.find_index(players, &(&1 == previous_player)) + 1

    if next_index >= Enum.count(players) do
      List.first(players)
    else
      Enum.at(players, next_index)
    end
  end

  defp remove_player(player, state) do
    Machine.remove_player(state.machine, player)
    players = Enum.filter(state.players, fn p -> p != player end)
    %{state | players: players}
  end

  defp strike_player(player, state) do
    new_count = if count = Map.get(state.expirations, player), do: count + 1, else: 1
    new_state = %{state | expirations: Map.put(state.expirations, player, new_count)}

    {new_state, new_count}
  end

  defp reset_turn_timer(next_player, state) do
    Process.cancel_timer(state.timer)
    Process.send(self(), {:next, next_player}, [:noconnect])

    %{state | timer: nil}
  end
end
