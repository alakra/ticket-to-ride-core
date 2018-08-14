defmodule TtrCore.Games.Action do
  alias TtrCore.Board.Route
  alias TtrCore.Cards.{
    TrainCard,
    TicketCard
  }

  @type count() :: integer()

  @type t :: {:claim_route, Route.t}
  | {:draw_train_cards, count()}
  | {:draw_ticket_cards, count()}
  | {:select_train_cards, [TrainCard.t]}
  | {:select_ticket_cards, [TicketCard.t]}
  | :end_turn
  | :force_end_turn
end
