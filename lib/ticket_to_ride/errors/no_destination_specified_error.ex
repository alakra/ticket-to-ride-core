defmodule TicketToRide.NoDestinationSpecifiedError do
  defexception [:from]

  def exception(args) do
    case args[:from] do
      nil -> raise ArgumentError, "Did not specify :from keyword when defining raise."
        _ -> %__MODULE__{from: args[:from]}
    end
  end

  def message(exception) do
    "Destination was not specified from city, #{exception.from}."
  end
end
