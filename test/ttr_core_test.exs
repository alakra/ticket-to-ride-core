defmodule TtrCoreTest do
  use ExUnit.Case, async: false

  alias TtrCore.Games.{
    Context,
    Index,
    State,
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
      # User Registration and Login

      assert {:ok, player_id_a} = Players.register("playerA", "p@ssw0rd!")
      assert {:ok, session_a} = Players.login("playerA", "p@ssw0rd!")

      assert {:ok, player_id_b} = Players.register("playerB", "p@ssw0rd!")
      assert {:ok, session_b} = Players.login("playerB", "p@ssw0rd!")

      # Game Setup

      assert {:ok, id, pid} = Games.create(session_a.user_id)
      assert {:ok, ids} = Games.list()

      assert :ok = Games.join(id, session_b.user_id)
      assert :ok = Games.setup(id, session_a.user_id)

      assert {:ok, %{tickets_buffer: tickets_a}} = Games.get_context(id, session_a.user_id)
      assert :ok = Games.perform(id, session_a.user_id, {:select_ticket_cards, tickets_a})

      assert {:ok, %{tickets_buffer: tickets_b}} = Games.get_context(id, session_b.user_id)
      assert Games.perform(id, session_b.user_id, {:select_ticket_cards, tickets_b})

      assert :ok = Games.begin(id, session_a.user_id)

      # Game Play - Automating this in a fixed loop

      ## Find out who goes first

      assert {:ok, context_a} = Games.get_context(id, session_a.user_id)
      assert {:ok, context_b} = Games.get_context(id, session_b.user_id)

      current_context = Enum.find([context_a, context_b], fn context ->
        context.current_player == context.id
      end)

      ### Check to see if a route can be claimed, if so claim it and end turn



      ### Check to see if trains can be drawn, if so draw 2 and end turn

      ### Check to see if tickets can be drawn, if so draw 1 and end turn

      # Finishing

      # Automatically move to last round if any player has 2 or less pieces left

      # Declare winner to log and shutdown game

    end
  end
end
