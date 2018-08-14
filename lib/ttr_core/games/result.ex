defmodule TtrCore.Games.Result do
  defstruct [
    :board,
    :cards,
    :players
  ]

  @type t :: %__MODULE__{}
end
