defmodule TtrCore.Games.State do
  defstruct [
    id: nil,
    owner_id: nil,
    players: [],
    routes: [],
    ticket_deck: [],
    displayed_trains: [],
    train_deck: [],
    discard_deck: [],
    current_player: nil,
    started?: false
  ]

  @type t :: %__MODULE__{}

  alias TtrCore.Cards.{TrainCard, TicketCard}

  # API

  def new(%{id: id, owner_id: oid, players: players}), do: new(id, oid, players)
  def new(id, owner_id, players) do
    {train_deck, players}   = shuffle_and_deal_from_train_deck(players)
    {ticket_deck, players}  = shuffle_and_select_from_ticket_deck(players)
    {displayed, train_deck} = display_trains(train_deck)

    chosen_player = select_random_player(players)

    {:ok, %__MODULE__{
        id: id,
        owner_id: owner_id,
        players: players,
        train_deck: train_deck,
        ticket_deck: ticket_deck,
        displayed_trains: displayed,
        discard_deck: [],
        current_player: chosen_player,
        started?: true
     }}
  end

  # Private

  defp select_random_player(players) do
    players
    |> Enum.take_random(1)
    |> hd()
  end

  defp shuffle_and_deal_from_train_deck(players) do
    TrainCard.shuffle |> TrainCard.deal_hands(players)
  end

  defp shuffle_and_select_from_ticket_deck(players) do
    TicketCard.shuffle |> TicketCard.select_hands(players)
  end

  @display_train_count 5
  defp display_trains(deck) do
    Enum.split(deck, @display_train_count)
  end
end
