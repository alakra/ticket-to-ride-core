defmodule TtrCore.Games.StartingTest do
  use ExUnit.Case, async: false

  alias TtrCore.{
    Games,
    Players
  }

  alias TtrCore.Games.{
    Index,
    State,
    Ticker,
    Turns
  }

  alias TtrCore.Players.Player

  setup do
    start_supervised({Registry, [keys: :unique, name: Index]})
    start_supervised({Registry, [keys: :duplicate, name: Turns]})
    start_supervised(Ticker)
    start_supervised(Players)
    start_supervised(Games)

    username_a = "foo"
    password_a = "P@ssw0rd"
    username_b = "bar"
    password_b = "P@ssw0rd"

    {:ok, user_id_a} = Players.register(username_a, password_a)
    {:ok, user_id_b} = Players.register(username_b, password_b)

    {:ok, game_id, _game_pid} = Games.create(user_id_a)

    :ok = Games.join(game_id, user_id_b)
    :ok = Games.setup(game_id, user_id_a)

    {:ok, game_id: game_id, owner_id: user_id_a, other_id: user_id_b}
  end

  describe "begin/2 with tickets selected" do
    setup %{game_id: game_id, owner_id: owner_id, other_id: other_id} do
      {:ok, %{tickets_buffer: owner_tickets}} = Games.get_context(game_id, owner_id)
      Games.perform(game_id, owner_id, {:select_ticket_cards, owner_tickets})

      {:ok, %{tickets_buffer: other_tickets}} = Games.get_context(game_id, other_id)
      Games.perform(game_id, other_id, {:select_ticket_cards, other_tickets})

      :ok
    end

    test "sucessfully begins start of a game", %{game_id: game_id, owner_id: owner_id, other_id: other_id} do
      assert :ok = Games.begin(game_id, owner_id)

      assert %State{
        id: ^game_id,
        owner_id: ^owner_id,
        current_player: random_id,
        players: [
          %Player{
            tickets: tickets_a,
            tickets_buffer: buffer_a,
            trains: trains_a
          },
          %Player{
            tickets: tickets_b,
            tickets_buffer: buffer_b,
            trains: trains_b
          }
        ],
        train_deck: train_deck,
        ticket_deck: ticket_deck,
        displayed_trains: displayed,
        discard_deck: [],
        stage: :started,
        stage_meta: [^other_id, ^owner_id]
      } = Games.get_state(game_id)

      assert Enum.count(displayed) == 5
      assert Enum.count(ticket_deck) == 24
      assert Enum.count(train_deck) == 97

      assert Enum.count(tickets_a) == 3
      assert buffer_a == []
      assert Enum.count(trains_a) == 4

      assert Enum.count(tickets_b) == 3
      assert buffer_b == []
      assert Enum.count(trains_b) == 4

      assert random_id == owner_id or random_id == other_id
    end

    test "returns error when game not found", %{owner_id: owner_id} do
      assert {:error, :not_found} = Games.begin("ABC", owner_id)
    end

    test "returns error when player trying to start game is not owner", %{game_id: game_id} do
      assert {:error, :not_owner} = Games.begin(game_id, "ABC")
    end

    test "returns error if there are not enough players joined to the game", %{game_id: game_id, owner_id: owner_id, other_id: other_id} do
      :ok = Games.leave(game_id, other_id)
      assert {:error, :not_enough_players} = Games.begin(game_id, owner_id)
    end

    test "returns error when game has already been started", %{game_id: game_id, owner_id: owner_id} do
      assert :ok = Games.begin(game_id, owner_id)
      assert {:error, :not_in_setup} = Games.begin(game_id, owner_id)
    end
  end

  describe "begin/2 with no tickets selected" do
    test "returns error when tickets are not selected", %{game_id: game_id, owner_id: owner_id} do
      assert {:error, :tickets_not_selected} = Games.begin(game_id, owner_id)
    end
  end
end
