defmodule TicketToRide.State do
  defstruct [
    turn: nil,
    players: [],
    routes: [],
    ticket_deck: [],
    displayed_trains: [],
    train_deck: [],
    discard_deck: []
  ]

  alias TicketToRide.{Player, TrainCard, TicketCard}

  # API

  def new(user_ids) do
    players = generate_players_from_users(user_ids)

    {train_deck, players}   = shuffle_and_deal_from_train_deck(players)
    {ticket_deck, players}  = shuffle_and_select_from_ticket_deck(players)
    {displayed, train_deck} = display_trains(train_deck)

    %__MODULE__{
      turn: List.first(players).id,
      players: players,
      train_deck: train_deck,
      ticket_deck: ticket_deck,
      displayed_trains: displayed,
      discard_deck: []
    }
  end

  def move_to_next_turn(state, current) do
    player_count = Enum.count(state.players)
    next = Enum.find_index(state.players, &(&1.id == current)) + 1

    if next < player_count do
      %{state | turn: Enum.at(state.players, next).id}
    else
      %{state | turn: Enum.at(state.players, 0).id}
    end
  end

  # Private

  defp shuffle_and_deal_from_train_deck(players) do
    TrainCard.shuffle |> TrainCard.deal_hands(players)
  end

  defp shuffle_and_select_from_ticket_deck(players) do
    TicketCard.shuffle |> TicketCard.select_hands(players)
  end

  @display_train_count 7
  defp display_trains(deck) do
    Enum.split(deck, @display_train_count)
  end

  defp generate_players_from_users(user_ids) do
    Enum.map(user_ids, &(%Player{id: &1}))
  end
end
