defmodule TicketToRide.Interface do
  use GenServer

  # API

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, [name: __MODULE__])
  end

  # Callbacks

  def init(_args) do
    {:ok, {}}
  end
end
