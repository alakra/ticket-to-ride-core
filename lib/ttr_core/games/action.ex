defmodule TtrCore.Games.Action do
  @moduledoc false

  alias TtrCore.Board.Route
  alias TtrCore.Cards.{
    TrainCard,
    TicketCard
  }

  @type count() :: integer()

  @type t :: {:claim_route, Route.t, TrainCard.t, count()}
  | {:draw_trains, count()}
  | {:draw_tickets, count()}
  | {:select_trains, [TrainCard.t]}
  | {:select_tickets, [TicketCard.t]}
  | :end_turn
  | :force_end_turn
end
