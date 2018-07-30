defmodule TtrCore.InsufficientTicketSelectionError do
  defexception [:required]

  def exception(args) do
    case args[:required] do
      nil -> raise ArgumentError, "Did not specify :required keyword when defining raise."
        _ -> %__MODULE__{required: args[:required]}
    end
  end

  def message(exception) do
    "You must select at least #{exception.required} tickets."
  end
end
