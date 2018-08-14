defmodule TtrCore.Cards.TrainCard do
  @moduledoc false

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

  @type t :: :box
  | :passenger
  | :tanker
  | :reefer
  | :freight
  | :hopper
  | :coal
  | :caboose
  | :locomotive

  @type deck :: [t]
  @type remaining :: deck()
  @type selected :: deck()

  # API

  def shuffle, do: shuffle(@car_counts, [])
  def shuffle([], deck), do: deck
  def shuffle(source, deck) do
    [{train, n}] = Enum.take_random(source, 1)

    source
    |> calculate_remainder(train, n)
    |> shuffle([train|deck])
  end

  @spec draw(deck(), integer()) ::
  {:ok, {remaining(), selected()}} |
  {:error, :invalid_deal}
  def draw(deck, n)
  def draw(deck, 4), do: {:ok, Enum.split(deck, 4)}
  def draw(deck, 2), do: {:ok, Enum.split(deck, 2)}
  def draw(deck, 1), do: {:ok, Enum.split(deck, 1)}
  def draw(deck, _), do: {:error, :invalid_deal}

  # Private

  defp calculate_remainder(source, train, 1), do: Keyword.delete(source, train)
  defp calculate_remainder(source, train, n), do: Keyword.put(source, train, n - 1)
end
