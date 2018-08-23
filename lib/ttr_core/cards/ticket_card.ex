defmodule TtrCore.Cards.TicketCard do
  @moduledoc false

  @type from :: atom()
  @type to :: atom()
  @type value :: integer()

  @type t :: {from(), to(), value()}

  @type deck :: [t]
  @type remaining :: deck()
  @type selected :: deck()

  @spec draw(deck()) :: {remaining(), selected()}
  def draw(deck), do: Enum.split(deck, 3)
end
