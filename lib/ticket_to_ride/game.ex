defmodule TicketToRide.Game do
  defstruct [:id, :owner, :users, :gamestate]

  use GenServer

  alias TicketToRide.State

  # API

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, [])
  end

  def id(game) do
    GenServer.call(game, :id)
  end

  def status(game) do
    GenServer.call(game, :status)
  end

  def begin(game) do
    GenServer.call(game, :start)
  end

  def join(game, user) do
    GenServer.call(game, {:join, user})
  end

  # Callback

  def init(opts) do
    {:ok, %__MODULE__{
        id: UUID.uuid1(:hex),
        owner: opts[:user],
        users: opts[:user],
        gamestate: nil}
    }
  end

  def handle_call(:id, _from, state) do
    {:reply, state.id, state}
  end

  def handle_call(:status, _from, state) do
    # TBD
  end

  def handle_call({:join, user}, _from, state) do
    {:reply, :ok, state}
  end

  def handle_call(:start, _from, state) do
    {:reply, :ok, State.generate(state.users)}
  end
end
