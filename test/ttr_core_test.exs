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

  alias TtrCore.Board

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

      assert {:ok, _} = Players.register("playerA", "p@ssw0rd!")
      assert {:ok, session_a} = Players.login("playerA", "p@ssw0rd!")

      assert {:ok, _} = Players.register("playerB", "p@ssw0rd!")
      assert {:ok, session_b} = Players.login("playerB", "p@ssw0rd!")

      # Game Setup

      assert {:ok, id, _pid} = Games.create(session_a.user_id)

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

      context = Enum.find([context_a, context_b], fn c ->
        c.current_player == c.id
      end)

      routes = Board.get_routes() |> Map.values()
      routes = (routes -- context_a.routes) -- context_b.routes

      ### Check to see if a route can be claimed, if so claim it and end turn
      ### Check to see if trains can be selected, if so draw 1 and end turn
      ### Check to see if trains can be drawn, if so draw 1 and end turn
      ### Check to see if tickets can be drawn, if so draw 1 and end turn

      %{context: context, finish_turn: false}
      |> claim_route(routes)
      |> select_train()
      |> draw_train()
      |> draw_tickets()
      |> end_turn()

      # Finishing

      ### Automatically move to last round if any player has 2 or less pieces left
      ### Declare winner to log and shutdown game

    end
  end

  # Private

  defp claim_route(%{context: %{id: id, game_id: game_id, trains: cards}} = status, routes) do
    {route_to_claim, train, cost} = Enum.reduce_while(routes, {:no_route, :no_train, 0}, fn
      %{train: :any, distance: distance} = route, acc ->
        # 1. Groups every held card into card -> count
        # 2. Compares each card count to the distance to see if there is at least enough to claim this route

        result = cards
        |> Enum.reduce(%{}, fn card, map -> Map.put(map, card, Map.get(map, card, 0) + 1) end)
        |> Enum.find(false, fn {_, count} -> count >= distance end)

        if result do
          {card, _} = result
          {:halt, {route, card, distance}}
        else
          {:cont, acc}
        end
      %{train: train, distance: distance} = route, acc ->
        # 1. Finds every card held that matches the train route
        # 2. Counts them
        # 3. Compares the count to the distance to see if there is at least enough to claim this route

        if Enum.count(cards, &(&1 == train)) >= distance do
          {:halt, {route, train, distance}}
        else
          {:cont, acc}
        end
    end)

    if route_to_claim == :no_route do
      status
    else
      :ok = Games.perform(game_id, id, {:claim_route, route_to_claim, train, cost})
      %{status | finish_turn: true}
    end
  end

  defp select_train(status) do
    status
  end

  defp draw_train(status) do
    status
  end

  defp draw_tickets(status) do
    status
  end

  defp end_turn(%{context: %{id: id, game_id: game_id}}) do
    Games.perform(game_id, id, :end_turn)
  end
end
