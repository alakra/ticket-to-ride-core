defmodule TtrCore.Players.Player do
  @moduledoc false

  alias TtrCore.Cards.TicketCard
  alias TtrCore.Players

  defstruct [
    id: 1,
    name: "anonymous",
    pieces: 45,
    tickets: [],
    tickets_buffer: [],
    trains: [],
    routes: [],
    track_score: 1
  ]

  @type count :: integer()

  @type t :: %__MODULE__{
    id: Players.user_id(),
    name: String.t,
    pieces: count(),
    tickets: [TicketCard.t],
    tickets_buffer: [TicketCard.t],
    trains: [TrainCard.t],
    routes: [Route.t],
    track_score: count()
  }

  @spec add_tickets(t, [TicketCard.t]) :: Player.t
  def add_tickets(%{tickets: existing} = player, new) do
    %{player | tickets: new ++ existing}
  end

  @spec add_tickets_to_buffer(t, [TicketCard.t]) :: Player.t
  def add_tickets_to_buffer(player, new) do
    %{player | tickets_buffer: new}
  end

  @spec add_trains(t, [TrainCard.t]) :: Player.t
  def add_trains(%{trains: existing} = player, new) do
    %{player | trains: new ++ existing}
  end

  @spec remove_tickets_from_buffer(t, [TicketCard.t]) :: {Player.t, [TicketCard.t]}
  def remove_tickets_from_buffer(player, selected) do
    remaining = player.tickets_buffer -- selected
    updated_player = %{player | tickets_buffer: []}
    {updated_player, remaining}
  end
end
