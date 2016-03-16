defmodule TicketToRide.NoRouteError do
  defexception [:name]

  def exception(args) do
    case args[:name] do
      nil -> raise ArgumentError, "Did not specify city name properly when error handling."
        _ -> %__MODULE__{name: args[:name]}
    end
  end

  def message(exception) do
    "Route from city, #{exception.name}, was not found."
  end
end
