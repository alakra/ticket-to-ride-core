defmodule TtrCore.Cards.TicketCard do
  @moduledoc false

  alias TtrCore.Cards.Tickets

  @type t :: atom()

  @type deck :: [t]
  @type remaining :: deck()
  @type selected :: deck()

  @spec draw(deck(), integer()) ::
  {:ok, {remaining(), selected()}} |
  {:error, :invalid_draw}
  def draw(deck, count) do
    if Enum.member?(0..3, count) do
      {:ok, Enum.split(deck, count)}
    else
      {:error, :invalid_draw}
    end
  end
end
