defmodule TicketToRide.Router do
  alias TicketotRide.{NoRouteFoundError,
                      NoDestinationSpecifiedError,
                      NoDistanceSpecifiedError}

  defmodule Route do
    defstruct [
      name: nil,
      destinations: %{}
    ]
  end

  defmodule Destination do
    defstruct [
      name: nil,
      distance: 0,
      trains: MapSet.new
    ]
  end

  defmacro __using__(_opts) do
    quote do
      import unquote(__MODULE__)
      Module.register_attribute __MODULE__, :routes, accumulate: false, persist: false
      @before_compile unquote(__MODULE__)
    end
  end

  defmacro defroute(name, args \\ []) do
    quote do
      updated_routes = get(name, autocreate: true) |> update_routes(args)
      @routes Map.merge(@routes, updated_routes)
    end
  end

  def all do
    @routes
  end

  def get(name, opts \\ [autocreate: false]) do
    case Map.fetch(@routes, name) do
      {:ok, route} -> route
      :error -> get_on_error(name, opts[:autocreate])
    end
  end

  defp get_on_error(name, autocreate) do
    if autocreate do
      %Route{name: name}
    else
      raise NoRouteFoundError, name: name
    end
  end

  defp update_routes(route, args) do
    [ build_original_route(route, args),
      build_reverse_route(route, args)]
  end

  defp build_orginal_route(route, args) do
    destination_name = extract_destination_name(route, args)
    trains = extract_trains(args)

    destination = update_destination(route, destination_name, trains, args)
    destinations = Map.put(route.destinations, destination_name, destination)

    %{route | destinations: destinations}
  end

  def update_destination(route, destination, trains, args) do
    case Map.fetch(route.destinations, destination) do
      {:ok, dest} ->
        %{dest | trains: MapSet.union(destination.trains, trains)}
      :error ->
        distance = extract_distance(args)
        %Destination{name: destination, distance: distance, trains: trains}
    end
  end

  defp extract_destination_name(route, args) do
    case args[:to] do
      nil -> raise NoDestinationSpecifiedError, from: route.name
      destination -> destination
    end
  end

  defp extract_distance(route, args) do
    case args[:distance] do
      nil -> raise NoDistanceSpecifiedError, from: route.name, to: args[:to]
      distance -> distance
    end
  end

  defp extract_trains(args) do
    case args[:trains] do
      nil -> MapSet.new([:any])
      trains -> MapSet.new(trains)
    end
  end
end
