defmodule TicketToRide.TrainCard do
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

  def shuffle do
    shuffle(@car_counts, [])
  end

  def shuffle([], deck) do
    deck
  end

  def shuffle(source, deck) do
    [{train, n}] = Enum.take_random(source, 1)
    calculate_remainder(source, train, n) |> shuffle(deck ++ [train])
  end

  def deal_hands(deck, players) do
    # TBD
  end

  defp calculate_remainder(source, train, 0) do
    Keyword.delete(source, train)
  end

  defp calculate_remainder(source, train, n) do
    Keyword.put(source, train, n - 1)
  end
end
