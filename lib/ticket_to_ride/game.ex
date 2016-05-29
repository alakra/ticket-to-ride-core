defmodule TicketToRide.Game do
  use GenServer

  alias TicketToRide.State

  # API

  def start_link(owner) do
    GenServer.start_link(__MODULE__, [owner], [])
  end

  def begin(game) do
    GenServer.call(game, :start)
  end

  def join(game, player_id) do
    GenServer.call(game, {:join, player_id})
  end

  # Callback

  def init(owner) do
    {:ok, %{owner: owner, gamestate: nil}}
  end

  def handle_call({:join, player_id}, from, state) do
    {:reply, :ok, state}
  end
end
