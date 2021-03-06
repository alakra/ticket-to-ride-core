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
    trains_selected: 0,
    routes: [],
  ]

  @type count :: integer()

  @type t :: %__MODULE__{
    id: Players.user_id(),
    name: String.t,
    pieces: count(),
    tickets: [TicketCard.t],
    tickets_buffer: [TicketCard.t],
    trains: [TrainCard.t],
    trains_selected: count(),
    routes: [Route.t]
  }

  @spec add_route(t, Route.t) :: t
  def add_route(%{routes: existing, pieces: pieces} = player, {_, _, cost, _} = new) do
    %{player | routes: [new|existing], pieces: pieces - cost}
  end

  @spec add_trains(t, [TrainCard.t]) :: t
  def add_trains(%{trains: existing} = player, new) do
    %{player | trains: new ++ existing}
  end

  @spec add_trains_on_turn(t, [TrainCard.t]) :: t
  def add_trains_on_turn(%{trains: existing, trains_selected: selected_count} = player, new) do
    %{player | trains: new ++ existing, trains_selected: Enum.count(new) + selected_count}
  end

  @spec remove_trains(t, TrainCard.t) :: {t, [TrainCard.t]}
  def remove_trains(%{trains: existing} = player, trains) do
    removed = existing -- trains
    updated_player = %{player | trains: removed}
    {updated_player, removed}
  end

  @spec add_tickets(t, [TicketCard.t]) :: t
  def add_tickets(%{tickets: existing} = player, new) do
    %{player | tickets: new ++ existing}
  end

  @spec add_tickets_to_buffer(t, [TicketCard.t]) :: t
  def add_tickets_to_buffer(player, new) do
    %{player | tickets_buffer: new}
  end

  @spec remove_tickets_from_buffer(t, [TicketCard.t]) :: {t, [TicketCard.t]}
  def remove_tickets_from_buffer(player, selected) do
    remaining = player.tickets_buffer -- selected
    updated_player = %{player | tickets_buffer: []}
    {updated_player, remaining}
  end

  @spec reset_selections(t) :: t
  def reset_selections(player) do
    %{player | trains_selected: 0}
  end

  @spec out_of_stock?(t) :: boolean()
  def out_of_stock?(%{pieces: pieces}) do
    pieces <= 2
  end
end
