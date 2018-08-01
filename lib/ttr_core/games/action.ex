defmodule TtrCore.Games.Action do
  @type command() ::
  :claim_route
  | :end_turn
  | :draw_faceup_train_cards
  | :draw_deck_train_cards
  | :draw_ticket_cards
  | :force_end_turn
  | :select_initial_destination_cards
  | :select_destination_cards

  @type details() ::
  :no_details

  @type player_id() :: binary()

  @type t ::
  command() | {command(), details()}
end
