defmodule TtrCore.Mechanics.Score do
  @moduledoc false

  alias TtrCore.Players.Player

  @type score :: integer
  @type route_score :: score
  @type ticket_score :: score
  @type longest_route_length :: integer
  @type t :: {Player.user_id, route_score, ticket_score, longest_route_length}

  # API

  @spec calculate(Player.t) :: t
  def calculate(%{id: id, routes: routes, tickets: tickets}) do
    longest_route = calculate_longest_route(routes)
    route_score   = calculate_route(routes)
    ticket_score  = calculate_tickets(tickets, routes)

    {id, route_score, ticket_score, longest_route}
  end

  # Private

  defp calculate_route(6), do: 15
  defp calculate_route(5), do: 10
  defp calculate_route(4), do: 7
  defp calculate_route(3), do: 4
  defp calculate_route(2), do: 2
  defp calculate_route(1), do: 1
  defp calculate_route(routes) do
    routes
    |> Enum.map(fn {_, _, distance, _} -> calculate_route(distance) end)
    |> Enum.sum()
  end

  defp calculate_tickets(tickets, routes) do
    Enum.reduce(tickets, 0, fn {from, to, value}, acc ->
      if ticket_has_route?(routes, from, to) do
        acc + value
      else
        acc - value
      end
    end)
  end

  defp ticket_has_route?(routes, from, to) do
    Enum.find(routes, false, fn {source, destination, _, _} = route ->
      cond do
        (source == from && destination == to) || (source == to && destination == from) ->
          true
        source == from ->
          ticket_has_route?(routes -- [route], destination, to)
        destination == from ->
          ticket_has_route?(routes -- [route], source, to)
        :no_route ->
          false
      end
    end)
  end

  defp calculate_longest_route(routes) do
    routes
    |> Enum.map(fn {_, _, value, _} = route ->
      calculate_longest(route, routes -- [route], value)
    end)
    |> Enum.max(fn -> 0 end)
  end

  defp calculate_longest(route, routes, acc) do
    connections = Enum.filter(routes, fn next -> is_connected?(route, next) end)

    if Enum.empty?(routes) or Enum.empty?(connections) do
      acc
    else
      connections
      |> Enum.map(fn {_, _, value, _} = next -> calculate_longest(next, routes -- [next], acc + value) end)
      |> Enum.max(fn -> 0 end)
    end
  end

  defp is_connected?({from_a, to_a, _, _}, {from_b, to_b, _, _}) do
    from_a == from_b || from_a == to_b || to_a == from_b || to_a == to_b
  end
end
