defmodule TtrCore.Games.CreationTest do
  use ExUnit.Case, async: false

  alias TtrCore.{
    Games,
    Players
  }

  alias TtrCore.Games.Index

  setup do
    start_supervised({Registry, [keys: :unique, name: Index]})
    start_supervised(Players)
    start_supervised(Games)

    :ok
  end

  describe "create/1" do
    test "creates a game successfully with a registered user id" do
      username = "test"
      password = "P@ssw0rd"

      assert {:ok, user_id} = Players.register(username, password)
      assert {:ok, _game_id, _game_pid} = Games.create(user_id)
    end

    test "fails to create game with unregisterd user id" do
      assert {:error, :invalid_user_id} = Games.create("BAD_ID")
    end
  end
end
