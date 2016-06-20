defmodule TicketToRide.Game do
  defstruct [:id, :owner, :users, :gamestate]

  use GenServer

  alias TicketToRide.State

  # API

  def start_link(owner) do
    GenServer.start_link(__MODULE__, [owner], [])
  end

  def id(game) do
    GenServer.call(game, :id)
  end

  def begin(game) do
    GenServer.call(game, :start)
  end

  def join(game, user) do
    GenServer.call(game, {:join, user})
  end

  # Callback

  def init(owner) do
    {:ok, %__MODULE__{
        id: UUID.uuid1(:hex),
        owner: owner,
        users: [owner],
        gamestate: nil}
    }
  end

  def handle_call(:id, _from, state) do
    {:reply, state.id, state}
  end

  def handle_call({:join, user}, _from, state) do
    {:reply, :ok, state}
  end

  def handle_call(:start, _from, state) do
    {:reply, :ok, State.generate(state.users)}
  end
end
