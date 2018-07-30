defmodule TtrCore.Cards.TicketCard do
  alias TtrCore.Cards.Tickets

  # API

  def shuffle do
    Tickets.all |> Enum.shuffle
  end

  def select_hands(deck, players) do
    {ticket_groups, _remainder} = split_tickets_into_groups(deck, players)

    {rejects, players} = Enum.zip(ticket_groups, players)
    |> gather_selections
    |> unpack_results

    {deck ++ rejects, players}
  end

  @max_hand_size 3
  defp gather_selections(candidates) do
    Enum.map(candidates, fn {group, player} ->
      {group, player}
# FIXME
# display_selection(group)
# make_selection(group, player)
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
end
