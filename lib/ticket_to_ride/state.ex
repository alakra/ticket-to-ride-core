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
    train_deck = generate_train_deck


    %__MODULE__{
      players: generate_players(n),
      routes: generate_routes,
      train_deck: train_deck,
      discard_deck: []
    }
  end

  defp generate_train_deck do
    TrainCard.breakdown
  end

  defp generate_players(n) do
    if n < 1 or n > 4, do: raise "You must choose between 1 and 4 players."
    for x <- 1..n, do: %Player{id: x}
  end

  defp generate_routes do
    Route.generate_all
  end
end
