defmodule TtrCore.Board.Route do
  @moduledoc false

  defstruct [:from, :to, :distance, :train]

  alias TtrCore.Cards.TrainCard

  @type t :: %__MODULE__{
    from: atom(),
    to: atom(),
    distance: integer(),
    train: TrainCard.t | :any
  }
end
