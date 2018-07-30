defmodule TtrCore.Board.Router do
  alias TtrCore.{NoOriginFoundError,
                 NoDestinationSpecifiedError,
                 NoDistanceSpecifiedError}

  defmodule Origin do
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
      Module.register_attribute __MODULE__, :origins, accumulate: false, persist: false
      Module.put_attribute __MODULE__, :origins, %{}
      @before_compile unquote(__MODULE__)
    end
  end

  # API

  defmacro defroute(name, args \\ []) do
    quote do
      @origins Map.merge(@origins, update_origins(@origins, unquote(name), unquote(args)))
    end
  end

  defmacro __before_compile__(_env) do
    quote do
      def all, do: @origins
      def get(name), do: Map.fetch(@origins, name)
    end
  end

  def update_origins(origins, name, args) do
    source = get(origins, name, autocreate: true)

    destination = get(origins, args[:to], autocreate: true)
    destination_options = [
      to: name,
      distance: args[:distance],
      trains: args[:trains]
    ]

    %{ name => update(source, args),
       args[:to] => update(destination, destination_options) }
  end

  # Private

  defp get(origins, name, opts) do
    case Map.fetch(origins, name) do
      {:ok, origin} -> origin
      :error -> get_on_error(name, opts[:autocreate])
    end
  end

  defp get_on_error(name, autocreate) do
    if autocreate do
      %Origin{name: name}
    else
      raise NoOriginFoundError, name: name
    end
  end

  defp update(origin, args) do
    destination_name = extract_destination_name(origin, args)
    trains = extract_trains(args)

    destination = update_destination(origin, destination_name, trains, args)
    destinations = Map.put(origin.destinations, destination_name, destination)

    %{origin | destinations: destinations}
  end

  defp update_destination(origin, destination, trains, args) do
    case Map.fetch(origin.destinations, destination) do
      {:ok, dest} ->
        %{dest | trains: MapSet.union(dest.trains, trains)}
      :error ->
        distance = extract_distance(origin, args)
        %Destination{name: destination, distance: distance, trains: trains}
    end
  end

  defp extract_destination_name(origin, args) do
    case args[:to] do
      nil -> raise NoDestinationSpecifiedError, from: origin.name
      destination -> destination
    end
  end

  defp extract_distance(origin, args) do
    case args[:distance] do
      nil -> raise NoDistanceSpecifiedError, from: origin.name, to: args[:to]
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
