defmodule TtrCore.Mechanics.DrawingTest do
  use ExUnit.Case, async: false

  alias TtrCore.Mechanics
  alias TtrCore.Mechanics.State
  alias TtrCore.Players.Player

  setup do
    {:ok, player: create_player()}
  end

  describe "draw_trains/3" do
    test "drawing from a train deck and discard deck that is empty", %{player: %{id: id} = player} do
      state = %State{
        train_deck: [],
        discard_deck: [],
        players: [player],
        current_player: id
      }

      {:ok, new_state} = Mechanics.draw_trains(state, player.id, 2)

      assert new_state == state
    end

    test "drawing from an empty train deck with a filled discard deck", %{player: %{id: id} = player} do
      state = %State{
        train_deck: [],
        discard_deck: [:caboose, :coal, :freight],
        players: [player],
        current_player: id
      }

      {:ok, new_state} = Mechanics.draw_trains(state, player.id, 2)

      assert %State{
        train_deck: deck,
        discard_deck: []
      } = new_state

      assert Enum.count(deck) == 1
    end
  end

  # Private

  defp create_player do
    %Player{id: "123"}
  end
end
