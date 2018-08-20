defmodule TtrCore.Board do
  @moduledoc """
  Information and operations directly related to game board.
  """

  alias TtrCore.Players.Player
  alias TtrCore.Board.Routes

  @type to :: atom()
  @type from :: atom()

  @doc """
  Get all routes
  """
  @spec get_routes() :: [Route.t]
  defdelegate get_routes(), to: Routes

  @doc """
  Get a specific route by specifying the origin and the destination.
  """
  @spec get_route(from(), to()) :: Route.t
  defdelegate get_route(from, to), to: Routes

  @doc """
  Gets all claimable routes by looking at what has not already been
  claimed by players.
  """
  @spec get_claimable_routes([Player.t]) :: [Route.t]
  def get_claimable_routes(players) do
    routes = get_routes() |> Map.values()

    Enum.reduce(players, routes, fn %{routes: taken}, acc ->
      acc -- taken
    end)
  end
end
