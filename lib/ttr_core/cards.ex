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
    Tickets.get_tickets() |> Enum.shuffle()
  end

  @doc """
  Deals train cards to a player. Can deal 1, 2 or 4 (on initial deal)
  cards.

  It returns the remaining train cards and the modified player.

  If you specify another number outside 1, 2 or 4, then an `{:error,
  :invalid_draw}` tuple is returned.
  """
  @spec deal_trains([TrainCard.t], Player.t, integer()) ::
  {:ok, TrainCard.deck(), Player.t} |
  {:error, :invalid_deal}
  def deal_trains(deck, player, count) do
    case TrainCard.draw(deck, count) do
      {:ok, {trains, new_deck}} ->
        {:ok, new_deck, Players.add_trains(player, trains)}
      error ->
        error
    end
  end

  @doc """
  Deals 4 train cards to multiple players. Used on initial deal.

  See `deal_trains/3` for  details.
  """
  @spec deal_initial_trains([TrainCard.t], [Player.t]) :: {[TrainCard.t], [Player.t]}
  def deal_initial_trains(train_deck, players) do
    Enum.reduce(players, {train_deck, []}, fn player, {deck, acc} ->
      {:ok, remainder, player} = deal_trains(deck, player, 4)
      {remainder, acc ++ [player]}
    end)
  end

  @doc """
  Draw trains for a particular player and adds them to a selection
  buffer. This also checks to see if player has selected cards from
  the train display in order not to overdraw.

  You may ask for up to 2 cards. If more is asked, the player will
  only get up to the max (including currently selected trains from the
  display deck).
  """
  @spec draw_trains([TrainDeck.t], Player.t, integer()) :: {[TrainDeck.t], Player.t}
  def draw_trains(deck, %{trains_selected: selected} = player, count) do
    real_count = min(count, max(0, 2 - selected))
    {:ok, {trains, new_deck}} = TrainCard.draw(deck, real_count)
    {new_deck, Players.add_trains_on_turn(player, trains)}
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
