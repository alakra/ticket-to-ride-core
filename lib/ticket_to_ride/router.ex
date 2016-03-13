defmodule TicketToRide.Router do
  defmodule Route do
    defstruct :start, :destination, :distance, :train


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
      @routes Map.put(@routes, name, get(@routes, name) |> modify_with(args))
    end
  end

  def routes do
    @routes
  end

  defp get(name) do
    case Map.fetch(@routes, name) do
      {:ok, route} -> route
      :error -> %Route{name: name}
    end
  end

  defp modify_with(route, args) do
    # TBD
  end
end
