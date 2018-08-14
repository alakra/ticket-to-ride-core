defmodule TtrCore.Cards do
  @moduledoc """
  Handles all card operations
  """

  alias TtrCore.Cards.{
    Tickets,
    TicketCard,
    TrainCard
  }

  alias TtrCore.Players
  alias TtrCore.Players.Player

  @doc """
  Returns a new list of train cards all shuffled.
  """
  @spec shuffle_trains() :: [TrainCard.t]
  def shuffle_trains do
    TrainCard.shuffle()
  end

  @doc """
  Returns a new list of ticket cards all shuffled.
  """
  @spec shuffle_tickets() :: [TicketCard.t]
  def shuffle_tickets do
    Tickets.all() |> Enum.shuffle()
  end

  @doc """
  Deals train cards to a player. Can deal up to 2 max cards.

  It returns the remaining train cards and the modified player as a
  tuple.

  If you specify more than 3, than an `{:error, :exceeded_maximum}`
  tuple is returned.
  """
  @spec deal_trains([TrainCard.t], Player.t, integer() | :initial) ::
  {:ok, TrainCard.deck(), Player.t} |
  {:error, :invalid_draw}
  def deal_trains(deck, player, count) do
    case TrainCard.draw(deck, count) do
      {:ok, {trains, new_deck}} ->
        {:ok, new_deck, Players.add_trains(player, trains)}
      error ->
        error
    end
  end

  @doc """
  Deals tickets cards to a player. Can deal 4 cards on initial game
  setup or deals 1 to 2 cards during gameplay. Player will choose what
  to keep.

  It returns the remaining tickets and the modified players as a
  tuple.

  If you specify more than 3, than an `{:error, :exceeded_maximum}`
  tuple is returned.

  """
  @spec deal_tickets([TicketCard.t], Player.t, integer() | :initial) ::
  {:ok, TicketCard.deck(), Player.t} |
  {:error, :invalid_draw}
  def deal_tickets(deck, player, count) do
    case TicketCard.draw(deck, count) do
      {:ok, {tickets, new_deck}} ->
        {:ok, new_deck, Players.add_tickets_to_buffer(player, tickets)}
      error ->
        error
    end
  end
end
