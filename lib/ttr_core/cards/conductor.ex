defmodule TtrCore.Cards.Conductor do
  @moduledoc false

  alias TtrCore.Cards.TicketCard

  defmacro __using__(_opts) do
    quote do
      import unquote(__MODULE__)
      Module.register_attribute __MODULE__, :tickets, accumulate: false, persist: true
      Module.put_attribute __MODULE__, :tickets, []
      @before_compile unquote(__MODULE__)
    end
  end

  # API

  defmacro defticket(from, args \\ []) do
    quote do
      opts     = unquote(args)
      from     = unquote(from)
      to       = opts[:to]
      value = opts[:value]

      @tickets [%TicketCard{from: from, to: to, value: value} | @tickets]
    end
  end

  defmacro __before_compile__(_env) do
    quote do
      def get_tickets, do: @tickets
    end
  end
end
