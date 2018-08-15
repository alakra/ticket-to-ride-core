defmodule TtrCore.Board do
  @moduledoc """
  Information and operations directly related to game board.
  """

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
end
