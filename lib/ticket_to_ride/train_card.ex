defmodule TicketToRide.TrainCard do

  # API

  @car_counts [
    box: 12,       # yellow
    passenger: 12, # blue
    tanker: 12,    # orange
    reefer: 12,    # white
    freight: 12,   # pink
    hopper: 12,    # black
    coal: 12,      # red
    caboose: 12,   # green
    locomotive: 14 # gold
  ]

  def shuffle, do: shuffle(@car_counts, [])
  def shuffle([], deck), do: deck
  def shuffle(source, deck) do
    [{train, n}] = Enum.take_random(source, 1)
    calc_remainder(source, train, n) |> shuffle(deck ++ [train])
  end

  @hand_size 4

  def deal_hands(deck, players), do: deal_hands(deck, players, @hand_size)
  def deal_hands(deck, players, 0), do: {deck, players}
  def deal_hands(deck, players, count) do
    {handout, deck} = Enum.split(deck, Enum.count(players))
    players = add_trains_to_players(handout, players)
    deal_hands(deck, players, count - 1)
  end

  # Private

  defp calc_remainder(source, train, 0), do: Keyword.delete(source, train)
  defp calc_remainder(source, train, n), do: Keyword.put(source, train, n - 1)

  defp add_trains_to_players(handout, players) do
    Enum.zip(handout, players) |> Enum.map(fn {card, player} ->
      %{player | trains: player.trains ++ [card]}
    end)
  end
end
