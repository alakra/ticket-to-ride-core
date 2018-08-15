defmodule TtrCore.Board.Route do
  @moduledoc false

  defstruct [:from, :to, :distance, :trains]

  alias TtrCore.Cards.TrainCard

  @type t :: %__MODULE__{
    from: atom(),
    to: atom(),
    distance: integer(),
    trains: [TrainCard.t] | :any
  }
end
