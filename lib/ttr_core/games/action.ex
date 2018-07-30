defmodule TtrCore.Games.Action do
  @type command() ::
  :force_end_turn
  | :end_turn

  @type details() ::
  :no_details

  @type player_id() :: binary()

  @type t ::
  {command(), player_id()}
  | {command(), player_id(), details()}
end
