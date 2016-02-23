defmodule TicketToRide.Engine do
  use GenServer

  alias TicketToRide.State

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, [], opts)
  end

  ## Callbacks

  def init(_args) do
    {:ok, State.generate([number_of_players: 4])}
  end
end
