defmodule TicketToRide.Game.Index do
  use GenServer

  @default_timeout 30_000

  # API

  def start_link do
    GenServer.start_link(__MODULE__, [], [name: __MODULE__])
  end

  def all do
    GenServer.call(__MODULE__, :all, @default_timeout)
  end

  def all(:ids) do
    GenServer.call(__MODULE__, {:all, :ids}, @default_timeout)
  end

  def get(id) do
    GenServer.call(__MODULE__, {:get, id}, @default_timeout)
  end

  def put(id, pid, state) do
    GenServer.call(__MODULE__, {:put, id, pid, state})
  end

  def remove(id) do
    GenServer.call(__MODULE__, {:remove, id})
  end

  # Callbacks

  @registry :game_registry

  def init(_args) do
    {:ok, :ets.new(@registry, [:set, :public, :named_table])}
  end

  def handle_call(:all, _from, state) do
    {:reply, :ets.lookup(@registry, :"$1"), state}
  end

  def handle_call({:all, :ids}, _from, state) do
    {:reply, :ets.lookup(@registry, {:"$1", :"_", :"_"}) |> List.flatten, state}
  end

  def handle_call({:get, id}, _from, state) do
    case :ets.lookup(@registry, id) do
      [] -> {:reply, :error, state}
      [results] -> {:reply, {:ok, results}, state}
    end
  end

  def handle_call({:put, id, pid, gamestate}, _from, state) do
    :ets.insert(@registry, {id, pid, gamestate})
    {:reply, id, state}
  end

  def handle_call({:remove, id}, _from, state) do
    :ets.insert(@registry, {id})
    {:reply, id, state}
  end
end
