defmodule TtrCore.Board.Route do
  @moduledoc false

  alias TtrCore.Cards.TrainCard

  @type city :: atom
  @type from :: city()
  @type to :: city()
  @type distance :: integer()
  @type train :: TrainCard.t | :any

  @type t :: {from(), to(), distance(), train()}
end
