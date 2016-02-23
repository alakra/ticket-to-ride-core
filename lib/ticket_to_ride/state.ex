defmodule TicketToRide.State do
  defstruct [
    turn: 0,
    players: [],
    routes: [],
    train_deck: [],
    discard_deck: []
  ]

  alias TicketToRide.{Player, Route, TrainCard}

  def generate(options) do
    n = options[:number_of_players]

    players = generate_players(n)

    train_deck  = shuffle_train_deck |> deal_train_hands(players)
    ticket_deck = shuffle_ticket_deck |> deal_ticket_hands(players)

    %__MODULE__{
      players: players,
      train_deck: train_deck,
      ticket_deck: ticket_deck,
      routes: generate_routes,
      displayed_trains: []
      discard_deck: []
    }
  end

  defp shuffle_train_deck do
    TrainCard.shuffle
  end

  defp shuffle_ticket_deck do
    TicketCard.shuffle
  end

  defp deal_train_hands(deck, players) do
    TrainCard.deal_hands(deck, players)
  end

  defp deal_ticket_hands(deck, players) do
    TicketCard.deal_hands(deck, players)
  end

  defp generate_players(n) do
    if n < 1 or n > 4, do: raise "You must choose between 1 and 4 players."
    for x <- 1..n, do: %Player{id: x}
  end

  defp generate_routes do
    Route.generate_all
  end
end
