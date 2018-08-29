defmodule TtrCore.Mechanics.ScoreTest do
  use ExUnit.Case, async: false

  alias TtrCore.Mechanics.Score
  alias TtrCore.Players.Player

  setup do
    {:ok, player: create_player()}
  end

  describe "calculate/1" do
    test "calculation of longest route", %{player: player} do
      assert {"123", _, _, 24} = Score.calculate(player)
    end

    test "calculation of total routes score", %{player: player} do
      assert {"123", 44, _, _} = Score.calculate(player)
    end

    test "calculation of tickets score", %{player: player} do
      assert {"123", _, -164, _} = Score.calculate(player)
    end
  end

  # Private

  @tickets [
    {Boston, Miami, 12},
    {Calgary, Phoenix, 13},
    {Chicago, New.Orleans, 7},
    {Chicago, Sante.Fe, 9},
    {Dallas, New.York, 11},
    {Denver, Pittsburgh, 11},
    {Duluth, El.Paso, 10},
    {Los.Angeles, Miami, 20},
    {Los.Angeles, New.York, 21},
    {Montreal, Atlanta, 9},
    {Portland, Phoenix, 11},
    {San.Francisco, Atlanta, 17},
    {Sault.St.Marie, Oklahoma.City, 9},
    {Toronto, Miami, 10},
    {Winnipeg, Houston, 12}
  ]

  @routes [
    {Atlanta, Raleigh, 2, :any},
    {Boston, Montreal, 2, :any},
    {Boston, New.York, 1, :coal},
    {Charleston, Raleigh, 2, :any},
    {Chicago, St.Louis, 2, :caboose},
    {Dallas, Houston, 1, :any},
    {Dallas, Little.Rock, 2, :any},
    {Dallas, Oklahoma.City, 2, :any},
    {Denver, Sante.Fe, 2, :any},
    {Duluth, Omaha, 2, :any},
    {El.Paso, Sante.Fe, 2, :any},
    {Houston, New.Orleans, 2, :any},
    {Kansas.City, Oklahoma.City, 2, :any},
    {Kansas.City, Omaha, 1, :any},
    {Little.Rock, Oklahoma.City, 2, :any},
    {Nashville, Raleigh, 3, :hopper},
    {Nashville, St.Louis, 2, :any},
    {New.York, Pittsburgh, 2, :caboose},
    {New.York, Washington, 2, :tanker},
    {Pittsburgh, Toronto, 2, :any},
    {Pittsburgh, Washington, 2, :any},
    {Raleigh, Washington, 2, :any},
    {Seattle, Vancouver, 1, :any}
  ]

  defp create_player() do
    %Player{id: "123", routes: @routes, tickets: @tickets}
  end
end
