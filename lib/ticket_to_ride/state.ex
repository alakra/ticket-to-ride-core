defmodule TicketToRide.State do
  defstruct [
    turn: 0,
    players: [],
    routes: [],
    ticket_deck: [],
    displayed_trains: [],
    train_deck: [],
    discard_deck: []
  ]

  alias TicketToRide.{Player, TrainCard, TicketCard}

  # API

  def generate(users) do
    players = generate_players_from_users(users)

    {train_deck, players}   = shuffle_and_deal_from_train_deck(players)
    {ticket_deck, players}  = shuffle_and_select_from_ticket_deck(players)
    {displayed, train_deck} = display_trains(train_deck)

    %__MODULE__{
      players: players,
      train_deck: train_deck,
      ticket_deck: ticket_deck,
      displayed_trains: displayed,
      discard_deck: []
    }
  end

  # Private

  defp shuffle_and_deal_from_train_deck(players) do
    TrainCard.shuffle |> TrainCard.deal_hands(players)
  end

  defp shuffle_and_select_from_ticket_deck(players) do
    TicketCard.shuffle |> TicketCard.select_hands(players)
  end

  @display_train_count 7
  defp display_trains(deck) do
    Enum.split(deck, @display_train_count)
  end

  defp generate_players_from_users(users) do
    Enum.map(users, &(%Player{id: &1.id}))
  end
end
