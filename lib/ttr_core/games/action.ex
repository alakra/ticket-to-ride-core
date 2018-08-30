defmodule TtrCore.Games.Action do
  @moduledoc false

  alias TtrCore.Board.Route
  alias TtrCore.Cards.{
    TicketCard,
    TrainCard
  }

  @type count() :: integer()

  @type t :: {:claim_route, Route.t, TrainCard.t, count()}
  | {:draw_trains, count()}
  | {:select_trains, [TrainCard.t]}
  | {:select_tickets, [TicketCard.t]}
  | :draw_tickets
  | :end_turn
  | :force_end_turn
end
