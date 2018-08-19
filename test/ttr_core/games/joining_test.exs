defmodule TtrCore.Games.JoiningTest do
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

  describe "join\2" do
    test "successfully joins a game" do
      username_a = "foo"
      password_a = "P@ssw0rd"

      assert {:ok, user_id_a} = Players.register(username_a, password_a)
      assert {:ok, game_id, _game_pid} = Games.create(user_id_a)

      username_b = "bar"
      password_b = "P@ssw0rd"

      assert {:ok, user_id_b} = Players.register(username_b, password_b)
      assert :ok = Games.join(game_id, user_id_b)
    end

    test "returns error if game does not exist" do
      username_b = "bar"
      password_b = "P@ssw0rd"

      assert {:ok, user_id_b} = Players.register(username_b, password_b)
      assert {:error, :not_found} = Games.join("BAD_ID", user_id_b)
    end

    test "returns error if user id does not exist" do
      username_a = "foo"
      password_a = "P@ssw0rd"

      assert {:ok, user_id_a} = Players.register(username_a, password_a)
      assert {:ok, game_id, _game_pid} = Games.create(user_id_a)

      assert {:error, :invalid_user_id} = Games.join(game_id, "BAD_ID")
    end

    test "returns error if game full" do
      username_a = "foo"
      password_a = "P@ssw0rd"

      assert {:ok, user_id_a} = Players.register(username_a, password_a)
      assert {:ok, game_id, _game_pid} = Games.create(user_id_a)

      username_b = "bar"
      password_b = "P@ssw0rd"

      assert {:ok, user_id_b} = Players.register(username_b, password_b)
      assert :ok = Games.join(game_id, user_id_b)

      username_c = "klass"
      password_c = "P@ssw0rd"

      assert {:ok, user_id_c} = Players.register(username_c, password_c)
      assert :ok = Games.join(game_id, user_id_c)

      username_d = "plass"
      password_d = "P@ssw0rd"

      assert {:ok, user_id_d} = Players.register(username_d, password_d)
      assert :ok = Games.join(game_id, user_id_d)

      username_e = "mlass"
      password_e = "P@ssw0rd"

      assert {:ok, user_id_e} = Players.register(username_e, password_e)
      assert {:error, :game_full} = Games.join(game_id, user_id_e)
    end

    test "returns error if user already joined" do
      username_a = "foo"
      password_a = "P@ssw0rd"

      assert {:ok, user_id_a} = Players.register(username_a, password_a)
      assert {:ok, game_id, _game_pid} = Games.create(user_id_a)
      assert {:error, :already_joined} = Games.join(game_id, user_id_a)
    end
  end
end
