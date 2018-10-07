defmodule TtrCore.Games.SetupTest do
  use ExUnit.Case, async: false

  alias TtrCore.{
    Games,
    Players
  }

  alias TtrCore.Mechanics.State

  alias TtrCore.Games.{
    Index,
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

    {:ok, game_id: game_id, owner_id: user_id_a, other_id: user_id_b}
  end

  describe "setup/2" do
    test "successfully begins setup of a game", %{game_id: game_id, owner_id: owner_id, other_id: other_id} do
      assert :ok = Games.setup(game_id, owner_id)

      assert {:ok, %State{
        id: ^game_id,
        owner_id: ^owner_id,
        current_player: nil,
        players: %{
          ^owner_id => %Player{
            tickets: tickets_a,
            tickets_buffer: buffer_a,
            trains: trains_a,
          },
          ^other_id => %Player{
            tickets: tickets_b,
            tickets_buffer: buffer_b,
            trains: trains_b
          }
        },
        train_deck: train_deck,
        ticket_deck: ticket_deck,
        displayed_trains: displayed,
        discard_deck: [],
        stage: :setup
      }} = Games.get_state(game_id)

      assert Enum.count(train_deck) == 97
      assert Enum.count(ticket_deck) == 24
      assert Enum.count(displayed) == 5

      assert tickets_a == []
      assert tickets_b == []

      assert Enum.count(buffer_a) == 3
      assert Enum.count(buffer_b) == 3

      assert Enum.count(trains_a) == 4
      assert Enum.count(trains_b) == 4
    end
  end

  test "returns error if game not found", %{owner_id: owner_id} do
    assert {:error, :not_found} = Games.setup("ABC", owner_id)
  end

  test "returns error if not the owner of the game", %{game_id: game_id} do
    assert {:error, :not_owner} = Games.setup(game_id, "ABC")
  end

  test "returns error if there are not enough players joined to the game", %{game_id: game_id, owner_id: owner_id, other_id: other_id} do
    :ok = Games.leave(game_id, other_id)
    assert {:error, :not_enough_players} = Games.setup(game_id, owner_id)
  end

  test "returns error if the existing state is not in an unstarted stage", %{game_id: game_id, owner_id: owner_id} do
    assert :ok = Games.setup(game_id, owner_id)
    assert {:error, :not_in_unstarted} = Games.setup(game_id, owner_id)
  end
end
