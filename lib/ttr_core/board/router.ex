defmodule TtrCore.Board.Router do
  @moduledoc false

  alias TtrCore.Board.Route

  defmacro __using__(_opts) do
    quote do
      import unquote(__MODULE__)
      Module.register_attribute __MODULE__, :routes, accumulate: true, persist: true
      @before_compile unquote(__MODULE__)
    end
  end

  defmacro defroute(from, args \\ []) do
    to       = args[:to]
    distance = args[:distance]
    trains   = args[:trains] || [:any]

    quote do
      Enum.each(unquote(trains), fn train ->
        @routes {unquote(from), unquote(to), unquote(distance), train}
      end)
    end
  end

  defmacro __before_compile__(_env) do
    quote do
      @spec get_routes() :: [Route.t]
      def get_routes, do: @routes

      @spec get_claimable_routes([Route.t], [Route.t], integer) :: [Route.t]
      def get_claimable_routes(claims, specific, player_count) do
        (normalize_routes_for_players(@routes, player_count) -- claims) -- specific
      end
    end
  end

  @doc false
  def normalize_routes_for_players(routes, count) when count > 3, do: routes
  def normalize_routes_for_players(routes, _), do: Enum.dedup(routes)
end
