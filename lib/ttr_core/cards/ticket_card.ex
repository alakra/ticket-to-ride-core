defmodule TtrCore.Cards.TicketCard do
  @moduledoc false

  defstruct [:from, :to, :value]

  @type t :: %__MODULE__{
    from: atom(),
    to: atom(),
    value: integer()
  }

  @type deck :: [t]
  @type remaining :: deck()
  @type selected :: deck()

  @spec draw(deck()) :: {remaining(), selected()}
  def draw(deck), do: Enum.split(deck, 3)
end
