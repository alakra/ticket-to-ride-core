defmodule TtrCore.PlayersTest do
  use ExUnit.Case, async: false

  alias TtrCore.Players
  alias TtrCore.Players.User

  setup do
    start_supervised(Players)
    :ok
  end

  describe "register/2" do
    test "returns success when registering a new username and password" do
      username = "test"
      password = "P@ssw0rd"

      assert {:ok, _id} = Players.register(username, password)
    end

    test "returns error when registering an existing username and password" do
      username = "test"
      password = "P@ssw0rd"

      {:ok, _id} = Players.register(username, password)
      assert {:error, :already_registered} = Players.register(username, password)
    end
  end

  describe "login/2" do
    test "returns a new session" do
      username = "test"
      password = "P@ssw0rd"

      {:ok, _id} = Players.register(username, password)

      assert {:ok, _session} = Players.login(username, password)
    end

    test "returns an error because of a wrong password" do
      username = "test"
      password = "P@ssw0rd"

      {:ok, _id} = Players.register(username, password)

      assert {:error, :incorrect_password} = Players.login(username, "no")
    end

    test "returns an error because of a wrong username" do
      assert {:error, :user_not_found} = Players.login("test", "test")
    end
  end

  describe "logout/1" do
    test "logout new session" do
      username = "test"
      password = "P@ssw0rd"

      {:ok, user_id} = Players.register(username, password)
      {:ok, session} = Players.login(username, password)

      assert [%User{id: ^user_id}] = Players.get_active_users()
      assert session.user_id == user_id
      assert :ok = Players.logout(user_id)
      assert [] = Players.get_active_users()
    end
  end

  describe "get_users/0" do
    test "gets all registered users" do
      username_a = "foo"
      password_a = "P@ssw0rd"

      {:ok, _id} = Players.register(username_a, password_a)

      username_b = "bar"
      password_b = "P@ssw0rd"

      {:ok, _id} = Players.register(username_b, password_b)

      assert [%User{}, %User{}] = Players.get_users()
    end
  end
end
