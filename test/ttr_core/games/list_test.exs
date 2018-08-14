defmodule TtrCore.GamesTest do
  use ExUnit.Case, async: false

  alias TtrCore.Games.Index

  alias TtrCore.{
    Games,
    Players
  }

  setup do
    start_supervised({Registry, [keys: :unique, name: Index]})
    start_supervised(Players)
    start_supervised(Games)

    :ok
  end

  describe "list/0" do
    test "returns empty list if no active games" do
      assert {:ok, []} = Games.list()
    end

    test "returns list of game ids that are active" do
      username = "test"
      password = "P@ssw0rd"

      assert {:ok, user_id} = Players.register(username, password)
      assert {:ok, game_id, _game_pid} = Games.create(user_id)
      assert {:ok, [^game_id]} = Games.list()
    end
  end
end
