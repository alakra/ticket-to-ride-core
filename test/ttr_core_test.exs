defmodule TtrCoreTest do
  use ExUnit.Case, async: false

  alias TtrCore.Games.{
    Index,
    Ticker,
    Turns
  }

  alias TtrCore.{
    Games,
    Players
  }

  setup do
    start_supervised({Registry, [keys: :unique, name: Index]})
    start_supervised({Registry, [keys: :duplicate, name: Turns]})

    start_supervised(Ticker)
    start_supervised(Players)
    start_supervised(Games)

    :ok
  end

  describe "main flow" do
    test "it all" do
      assert {:ok, player_id_a} = Players.register("playerA", "p@ssw0rd!")
      assert {:ok, session_a} = Players.login("playerA", "p@ssw0rd!")

      assert {:ok, player_id_b} = Players.register("playerB", "p@ssw0rd!")
      assert {:ok, session_b} = Players.login("playerB", "p@ssw0rd!")

      assert {:ok, id, pid} = Games.create(session_a.user_id)
      assert {:ok, ids} = Games.list()

      assert :ok = Games.join(id, session_b.user_id)
      assert :ok = Games.begin(id, session_a.user_id)

      assert {:ok, destination_cards} = Games.perform(id, session_a.user_id, :select_initial_destination_cards)
      assert :ok = Games.perform(id, session_a.user_id, {:select_initial_destination_cards, Enum.take_random(destination_cards, 2)})

      assert {:ok, destination_cards} = Games.perform(id, session_b.user_id, :select_initial_destination_cards)
      assert :ok = Games.perform(id, session_b.user_id, {:select_initial_destination_cards, Enum.take_random(destination_cards, 2)})

      assert :ok = Games.is_ready(id, session_a.user_id)
      assert :ok = Games.is_ready(id, session_b.user_id)

      assert {:ok, state} = Games.get_info(id, session_a.user_id)
    end
  end
end
