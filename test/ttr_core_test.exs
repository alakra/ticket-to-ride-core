defmodule TtrCoreTest do
  use ExUnit.Case, async: false

  alias TtrCore.Games.{
    Index,
    Ticker,
    Turns
  }

  alias TtrCore.{
    Board,
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

      assert {:ok, _} = Players.register("playerA", "p@ssw0rd!")
      assert {:ok, session_a} = Players.login("playerA", "p@ssw0rd!")

      assert {:ok, _} = Players.register("playerB", "p@ssw0rd!")
      assert {:ok, session_b} = Players.login("playerB", "p@ssw0rd!")

      # Game Setup

      assert {:ok, id, _pid} = Games.create(session_a.user_id)

      assert :ok = Games.join(id, session_b.user_id)
      assert :ok = Games.setup(id, session_a.user_id)

      assert {:ok, %{tickets_buffer: tickets_a}} = Games.get_context(id, session_a.user_id)
      assert :ok = Games.perform(id, session_a.user_id, {:select_tickets, tickets_a})

      assert {:ok, %{tickets_buffer: tickets_b}} = Games.get_context(id, session_b.user_id)
      assert Games.perform(id, session_b.user_id, {:select_tickets, tickets_b})

      assert :ok = Games.begin(id, session_a.user_id)

      main_loop(id, session_a, session_b)
    end
  end

  # Private

  defp main_loop(id, session_a, session_b) do
    {:ok, %{stage: stage} = state} = Games.get_state(id)

    if stage == :finished do
      assert state.winner_id
      assert is_integer(state.winner_score)

      assert state.players
      |> Enum.map(&(Enum.count(&1.tickets)))
      |> Enum.sum() == 30
    else
      assert {:ok, context_a} = Games.get_context(id, session_a.user_id)
      assert {:ok, context_b} = Games.get_context(id, session_b.user_id)

      context = Enum.find([context_a, context_b], fn c ->
        c.current_player == c.id
      end)

      player = Players.find_by_id(state.players, context.id)

      routes = [context_a, context_b]
      |> Enum.flat_map(fn %{routes: routes} -> routes end)
      |> Board.get_claimable_routes(player, Enum.count(state.players))

      %{context: context, finish_turn: false}
      |> claim_route(routes)
      |> select_trains()
      |> draw_trains()
      |> draw_tickets()
      |> select_tickets()
      |> end_turn()

      main_loop(id, session_a, session_b)
    end
  end

  defp claim_route(%{context: %{pieces: pieces}} = status, _routes) when pieces <= 2, do: status
  defp claim_route(%{context: %{id: id, game_id: game_id, trains: cards}} = status, routes) do
    {route_to_claim, train, cost} = Enum.reduce_while(routes, {:no_route, :no_train, 0}, fn
      {_, _, distance, :any} = route, acc ->
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

      {_, _, distance, train} = route, acc ->
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
      case Games.perform(game_id, id, {:claim_route, route_to_claim, train, cost}) do
        :ok -> %{status | finish_turn: true}
        {:error, _} -> status
      end
    end
  end

  defp select_trains(%{finish_turn: true} = status), do: status
  defp select_trains(status) do
    %{context:
      %{
        id: user_id,
        game_id: game_id,
        displayed_trains: displayed
      }
    } = status

    if not Enum.empty?(displayed) do
      first = List.first(displayed)
      :ok = Games.perform(game_id, user_id, {:select_trains, [first]})
    end

    status
  end

  defp draw_trains(%{finish_turn: true} = status), do: status
  defp draw_trains(status) do
    %{context:
      %{
        id: user_id,
        game_id: game_id,
        train_deck: deck
      }
    } = status

    if deck > 0 do
      :ok = Games.perform(game_id, user_id, {:draw_trains, 1})
    end

    status
  end

  defp draw_tickets(%{finish_turn: true} = status), do: status
  defp draw_tickets(status) do
    %{context:
      %{
        id: user_id,
        game_id: game_id,
        ticket_deck: deck
      }
    } = status

    if deck >= 3 do
      :ok = Games.perform(game_id, user_id, :draw_tickets)
    end

    status
  end

  defp select_tickets(%{finish_turn: true} = status), do: status
  defp select_tickets(status) do
    %{context:
      %{
        id: user_id,
        game_id: game_id
      }
    } = status

    {:ok, %{tickets_buffer: buffer}} =
      Games.get_context(game_id, user_id)

    if not Enum.empty?(buffer) do
      :ok = Games.perform(game_id, user_id, {:select_tickets, buffer})
    end

    status
  end

  defp end_turn(%{context: %{id: id, game_id: game_id}}) do
    Games.perform(game_id, id, :end_turn)
  end
end
