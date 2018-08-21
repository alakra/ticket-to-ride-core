defmodule TtrCore.Cards.Conductor do
  @moduledoc false

  alias TtrCore.Cards.TicketCard

  defmacro __using__(_opts) do
    quote do
      import unquote(__MODULE__)
      Module.register_attribute __MODULE__, :tickets, accumulate: true, persist: true
      @before_compile unquote(__MODULE__)
    end
  end

  # API

  defmacro defticket(from, args \\ []) do
    to    = args[:to]
    value = args[:value]

    quote do
      @tickets {unquote(from), unquote(to), unquote(value)}
    end
  end

  defmacro __before_compile__(_env) do
    quote do
      @spec get_tickets() :: [TicketCard.t]
      def get_tickets, do: @tickets
    end
  end
end
