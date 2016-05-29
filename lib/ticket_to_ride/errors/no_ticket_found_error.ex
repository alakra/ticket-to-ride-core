defmodule TicketToRide.NoTicketFoundError do
  defexception [:name]

  def exception(args) do
    case args[:name] do
      nil -> raise ArgumentError, "Did not specify :name keyword when defining raise."
        _ -> %__MODULE__{name: args[:name]}
    end
  end

  def message(exception) do
    "Ticket from city, #{exception.name}, was not found."
  end
end
