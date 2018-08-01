defmodule TtrCore.Player.SessionTest do
  use ExUnit.Case, async: true

  alias TtrCore.Player.{
    DB,
    Session
  }

  describe "start_link/0" do
    test "starts agent" do
      assert {:ok, _} = Session.start_link()
    end
  end

  describe "child_spec/1" do
    test "returns worker specification" do
      assert %{
        id: Session,
        start: {Session, :start_link, _},
        type: :worker
      } = Session.child_spec(:nada)
    end
  end

  describe "new/2" do
    setup do
      {:ok, _} = DB.start_link()
      {:ok, _} = Session.start_link()

      :ok
    end

    test "returns a new session" do
      username = "test"
      password = "P@ssw0rd"

      :ok = DB.register(username, password)

      assert {:ok, _session} = Session.new(username, password)
    end

    test "returns an error because of a wrong password" do
      username = "test"
      password = "P@ssw0rd"

      :ok = DB.register(username, password)

      assert {:error, "Password does not match."} = Session.new(username, "no")
    end

    test "returns an error because of a wrong username" do
      assert {:error, "User does not exist."} = Session.new("test", "test")
    end
  end
end
