defmodule TtrCore.Cards.TrainCardTest do
  use ExUnit.Case, async: false

  alias TtrCore.Cards
  alias TtrCore.Players.Player

  describe "shuffle_trains/0" do
    test "returns shuffled deck of trains" do
      shuffled = Cards.shuffle_trains()
      assert Enum.count(shuffled) == 110
    end
  end

  describe "deal_trains/3" do
    test "deals 1, 2 or 4 cards to player" do
      deck = Cards.shuffle_trains
      player = %Player{}

      assert {:ok, updated_deck, updated_player} =
        Cards.deal_trains(deck, player, 2)

      assert %Player{trains: trains} = updated_player
      assert Enum.count(trains) == 2
      assert Enum.count(updated_deck) == 108
    end

    test "return error if dealing outside the set of cards (1, 2, or 4) to player" do
      deck = Cards.shuffle_trains
      player = %Player{}

      assert {:error, :invalid_deal} = Cards.deal_trains(deck, player, 3)
    end
  end
end
