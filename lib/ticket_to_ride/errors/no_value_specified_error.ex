defmodule TicketToRide.NoValueSpecifiedError do
  defexception [:from, :to]

  def exception(args) do
    %__MODULE__{from: get_from!(args), to: get_to!(args)}
  end

  def message(exception) do
    "Value was not specified for ticket from city, #{exception.from}, to city, #{exception.to}."
  end

  defp get_from!(args) do
    case args[:from] do
      nil -> raise ArgumentError, "Did not specify :from keyword when defining raise."
      from -> from
    end
  end

  defp get_to!(args) do
    case args[:to] do
      nil -> raise ArgumentError, "Did not specify :to keyword when defining raise."
      to -> to
    end
  end
end
