defmodule TtrCore.Cards do
  @moduledoc """
  Handles all card operations related to deck management and assigment
  to players.
  """

  alias TtrCore.Cards.{
    TicketCard,
    Tickets,
    TrainCard
  }

  alias TtrCore.Players
  alias TtrCore.Players.Player

  @type card :: TrainCard.t | TicketCard.t

  @doc """
  Add trains to discard and returned updated discard pile.
  """
  @spec add_trains_to_discard([TrainCard.t], [TrainCard.t]) :: [TrainCard.t]
  def add_trains_to_discard(discard, to_remove) do
    discard ++ to_remove
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
  Deals 3 tickets to each player.

  It returns the remaining tickets and the modified players as a
  tuple.
  """
  @spec deal_tickets([TicketCard.t], [Player.t]) :: {[TicketCard.t], [Player.t]}
  def deal_tickets(ticket_deck, players) do
    Enum.reduce(players, {ticket_deck, []}, fn player, {deck, acc} ->
      {remainder, player} = draw_tickets(deck, player)
      {remainder, acc ++ [player]}
    end)
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
  Draws 3 tickets cards for a player and adds them to a selection
  buffer.

  It returns the remaining tickets and the modified player as a
  tuple.
  """
  @spec draw_tickets([TicketCard.t], Player.t) :: {[TicketCard.t], Player.t}
  def draw_tickets(deck, player) do
    {tickets, new_deck} = TicketCard.draw(deck)
    updated_player = Players.add_tickets_to_buffer(player, tickets)
    {new_deck, updated_player}
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
  Checks to see if a set of cards (`deck2`) are a subset of another (`deck1`).
  """
  @spec has_cards?([card()], [card()]) :: boolean()
  def has_cards?(deck1, deck2) do
    set1 = MapSet.new(deck2)
    set2 = MapSet.new(deck1)

    MapSet.subset?(set1, set2)
  end

  @doc """
  Return tickets from a selection to the bottom of the deck of tickets
  """
  @spec return_tickets([TicketCard.t], [TicketCard.t]) :: [TicketCard.t]
  def return_tickets(ticket_deck, to_return) do
    ticket_deck ++ to_return
  end

  @doc """
  Removes a set of trains from the displayed set.
  """
  @spec remove_from_display([TrainCard.t], [TrainCard.t]) :: [TrainCard.t]
  def remove_from_display(displayed, selections) do
    displayed -- selections
  end

  @doc """
  Replenish display with train cards (up to 5).

  Returns a tuple of `{display, train_deck}` where `display` and
  `train_deck` are both a list of `TrainCard`.
  """
  @spec replenish_display([TrainCard.t], [TrainCard.t]) :: {[TrainCard.t], [TrainCard.t]}
  def replenish_display(displayed, deck) do
    {additions, new_deck} = Enum.split(deck, 5 - Enum.count(displayed))
    {displayed ++ additions, new_deck}
  end

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
end
