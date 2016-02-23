defmodule TicketToRide.TrainCard do
  @car_counts [
    box: 12,
    passenger: 12,
    tanker: 12,
    reefer: 12,
    freight: 12,
    hopper: 12,
    coal: 12,
    caboose: 12,
    locomotive: 14
  ]

  def shuffle do
    shuffle(@car_counts, [])
  end

  def shuffle([], deck) do
    deck
  end

  def shuffle(source, deck) do
    [{train, n}] = Enum.take_random(source, 1)

    calculate_remainder(source, train, n)
    |> shuffle(deck ++ [train])
  end

  defp calculate_remainder(source, train, n) do
    n = n - 1

    if n == 0 do
      Keyword.delete(source, train)
    else
      Keyword.put(source, train, n)
    end
  end
end
