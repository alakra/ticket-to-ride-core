defmodule TtrCore.Board.Router do
  @moduledoc false

  alias TtrCore.Board.Route

  defmacro __using__(_opts) do
    quote do
      import unquote(__MODULE__)
      Module.register_attribute __MODULE__, :routes, accumulate: false, persist: true
      Module.put_attribute __MODULE__, :routes, %{}
      @before_compile unquote(__MODULE__)
    end
  end

  defmacro defroute(from, args \\ []) do
    quote do
      opts     = unquote(args)
      from     = unquote(from)
      to       = opts[:to]
      distance = opts[:distance]
      trains   = opts[:trains] || [:any]

      Enum.each(trains, fn train ->
        route = %Route{
          from: from,
          to: to,
          distance: distance,
          train: train
        }

        @routes Map.put(@routes, {from, to}, route)
      end)
    end
  end

  defmacro __before_compile__(_env) do
    quote do
      def get_routes, do: @routes
      def get_route(from, to), do: Map.fetch(@routes, {from, to})
    end
  end
end
