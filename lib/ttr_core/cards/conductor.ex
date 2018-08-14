defmodule TtrCore.Cards.Conductor do
  @moduledoc false

  alias TtrCore.Board.Routes
  alias TtrCore.{
    NoTicketFoundError,
    NoDestinationSpecifiedError,
    NoValueSpecifiedError
  }

  defmodule Ticket do
    defstruct [
      name: nil,
      destination: nil,
      value: 0
    ]
  end


  defmacro __using__(_opts) do
    quote do
      import unquote(__MODULE__)
      Module.register_attribute __MODULE__, :tickets, accumulate: false, persist: false
      Module.put_attribute __MODULE__, :tickets, []
      @before_compile unquote(__MODULE__)
    end
  end

  # API

  defmacro defticket(name, args \\ []) do
    quote do
      @tickets [build_ticket(unquote(name), unquote(args))] ++ @tickets
    end
  end

  defmacro __before_compile__(_env) do
    quote do
      def all, do: @tickets
    end
  end

  def build_ticket(name, args) do
    name  = verify_name(name)
    to    = verify_destination(name, args)
    value = verify_value(name, to, args)

    %Ticket{name: name, destination: to, value: value}
  end

  defp verify_name(name) do
    case Routes.get(name) do
      {:ok, _} -> name
      :error -> raise NoTicketFoundError, name: name
    end
  end

  defp verify_destination(name, args) do
    case args[:to] do
      nil -> raise NoDestinationSpecifiedError, from: name
      destination -> destination
    end
  end

  defp verify_value(name, to, args) do
    case args[:value] do
      nil -> raise NoValueSpecifiedError, from: name, to: to
      value -> value
    end
  end
end
