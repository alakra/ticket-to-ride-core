defmodule TtrCore.Board do
  @moduledoc """
  Information and operations directly related to game board.
  """

  alias TtrCore.Board.Routes
  alias TtrCore.Players.Player

  @type player_count :: integer
  @type all_claims :: [Route.t]

  @doc """
  Get all routes
  """
  @spec get_routes() :: [Route.t]
  defdelegate get_routes, to: Routes

  @doc """
  Gets all claimable routes by looking at what has not already been
  claimed by all other players and what has been claimed by a specific
  player.

  In the case of 2 or 3 players games, double routes are not up for
  grabs after a player has already claimed one of them and will not be
  returned in the claimable list.
  """
  @spec get_claimable_routes([Route.t], Player.t, player_count()) :: [Route.t]
  def get_claimable_routes(claimed, %{routes: routes}, player_count) do
    Routes.get_claimable_routes(claimed, routes, player_count)
  end
end
