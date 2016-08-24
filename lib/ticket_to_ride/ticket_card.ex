defmodule TicketToRide.TicketCard do
  alias TicketToRide.{
    Tickets,
    Player,
    InsufficientTicketSelectionError
  }

  # API

  def shuffle do
    Tickets.all |> Enum.shuffle
  end

  def select_hands(deck, players) do
    {ticket_groups, remainder} = split_tickets_into_groups(deck, players)

    {rejects, players} = Enum.zip(ticket_groups, players)
    |> gather_selections
    |> unpack_results

    {deck ++ rejects, players}
  end

  @max_hand_size 3
  defp gather_selections(candidates) do
    Enum.map(candidates, fn {group, player} ->
      display_selection(group)
      make_selection(group, player)
    end)
  end

  defp unpack_results(results) do
    rejects = Enum.map(results, fn {_, rejects} -> rejects end)
    players = Enum.map(results, fn {players, _} -> players end)

    {rejects, players}
  end

  defp split_tickets_into_groups(deck, players) do
    total = Enum.count(players) * @max_hand_size
    {candidates, remainder} = Enum.split(deck, total)
    {candidates |> Enum.chunk(@max_hand_size, @max_hand_size, []), remainder}
  end

  defp make_selection(group, player) do
    # TODO: Move prompt to client and forward through server API
    #    Process.group_leader
    #    |> IO.gets(prompt(player))
    # For now hardcoded to 0 and 1
    "0,1" |> parse_selection(group, player)
  end

  @required_tickets 2
  defp parse_selection(input, group, player) do
    try do
      selections = input
      |> String.split(",")
      |> Enum.map(&(String.strip(&1)))
      |> Enum.map(&(String.to_integer(&1)))
      |> Enum.uniq
      |> Enum.map(&(Enum.at(group, &1)))
      |> Enum.filter(&(is_map(&1)))

      if Enum.count(selections) < @required_tickets do
        raise InsufficientTicketSelectionError, required: @required_tickets
      end

      rejects = group -- selections

      {%{player | tickets: selections}, rejects}
    rescue
      e in [InsufficientTicketSelectionError] ->
        e
        |> InsufficientTicketSelectionError.message
        |> IO.puts

        make_selection(group, player)
      ArgumentError ->
        IO.puts("Invalid input. Try again.")
        make_selection(group, player)
    end
  end

  defp display_selection(ticket_group) do
    Enum.with_index(ticket_group)
    |> Enum.each(fn {ticket, index} ->
      name = city_to_string(ticket.name)
      destination = city_to_string(ticket.destination)

      [
        :blue, :bright,
        "#{index}: ",
        :default_color,
        "#{name} <--> #{destination} ",
        :faint,
        "=> ",
        :reset,
        :green, :bright,
        "#{ticket.value} ",
        :reset,
        "points"]
      |> IO.ANSI.format
      |> IO.puts
    end)

    IO.puts ""
  end

  defp city_to_string(city) do
    Module.split(city)
    |> Enum.join(".")
  end

  defp prompt(player) do
    [ :red, :bright,
      "Player #{player.id}: ",
      :default_color,
      "Pick which tickets you would like to keep. You must choose at least 2. (separate selections by commas e.g. `0,2`): "
    ] |> IO.ANSI.format
  end
end
