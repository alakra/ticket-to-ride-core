defmodule TicketToRide.Game.Machine do
  use GenServer

  alias TicketToRide.{State,Player}

  # API

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, [])
  end

  def generate(pid), do: GenServer.call(pid, :generate)
  def restore(pid, :restore, value), do: GenServer.call(pid, {:restore, value})

  def get(pid, :players), do: GenServer.call(pid, {:get, :players})
  def get(pid, :owner), do: GenServer.call(pid, {:get, :owner})

  def add_player(pid, id), do: GenServer.call(pid, {:add_player, id})
  def remove_player(pid, id), do: GenServer.call(pid, {:remove_player, id})

  # Callback

  def init(opts) do
    {:ok, %State{owner: opts[:owner], players: []}}
  end

  def handle_call(:generate, _from, state) do
    case State.new(state.owner, state.players) do
      {:ok, new_state} -> {:reply, {:ok, new_state}, new_state}
      {:error, msg} -> {:reply, {:error, msg}, nil}
    end
  end

  def handle_call({:restore, backup}, _from, _state) do
    {:reply, :ok, backup}
  end

  def handle_call({:get, :players}, _from, st), do: {:reply, st.players, st}
  def handle_call({:get, :owner}, _from, st), do: {:reply, st.owner, st}

  def handle_call({:add_player, player_id}, _from, state) do
    players = [%Player{id: player_id}|state.players]
    {:reply, :ok, %{state | players: players}}
  end

  def handle_call({:remove_player, player_id}, _from, state) do
    # TODO: Push his cards back onto the stack

    index = Enum.find_index(state.players, &(&1.id == player_id))
    new_players = List.delete(state.players, index)
    new_state = Map.put(state, :players, new_players) |> transfer_ownership_if_host_left

    {:reply, :ok, new_state}
  end

  # Private

  defp transfer_ownership_if_host_left(state) do
    result = Enum.any?(state.players, fn id -> id == state.owner end)

    if result do
      %{state | owner: List.first(state.players)}
    else
      state
    end
  end
end
