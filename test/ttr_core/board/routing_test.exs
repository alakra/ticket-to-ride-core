defmodule TtrCore.Board.RouterTest do
  use ExUnit.Case, async: false

  alias TtrCore.Board
  alias TtrCore.Players.Player

  setup do
    player = create_player()

    {:ok, player: player}
  end

  describe "get_claimable_routes/2" do
    test "ensure claims that are already taken are not in claimable routes", %{player: player} do
      assert Enum.count(Board.get_claimable_routes([], player, 4)) == 99

      claimed = {Atlanta, Charleston, 2, :any}
      claimable = Board.get_claimable_routes([claimed], player, 4)

      assert Enum.count(claimable) == 98
      assert claimed not in claimable
    end

    test "ensure that games of 2 or 3 players do not return double routes after at least one of them has been claimed", %{player: player} do
      assert Enum.count(Board.get_claimable_routes([], player, 2)) == 91

      claimed = {Boston, Montreal, 2, :any}
      claimable = Board.get_claimable_routes([claimed], player, 3)

      assert Enum.count(claimable) == 90
      assert claimed not in claimable
    end

    test "ensure that games of 4 or more players do return the next double route after the first one has been taken", %{player: player} do
      assert Enum.count(Board.get_claimable_routes([], player, 4)) == 99

      claimed = {Boston, Montreal, 2, :any}
      claimable = Board.get_claimable_routes([claimed], player, 5)

      assert Enum.count(claimable) == 98
      assert claimed in claimable

      # if player already owns this route, he should not get it in his list of potential routes
      claimable = Board.get_claimable_routes([claimed], %{player | routes: [claimed]}, 5)
      assert claimed not in claimable
    end
  end

  # Private

  defp create_player do
    %Player{routes: []}
  end
end
