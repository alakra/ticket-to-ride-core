defmodule TtrCore.Board do
  @moduledoc """
  Information and operations directly related to game board.
  """

  alias TtrCore.Board.Routes

  @doc """
  Get all routes
  """
  @spec get_routes() :: [Route.t]
  defdelegate get_routes(), to: Routes

  @doc """
  Gets all claimable routes by looking at what has not already been
  claimed.
  """
  @spec get_claimable_routes([Route.t]) :: [Route.t]
  defdelegate get_claimable_routes(claimed), to: Routes
end
