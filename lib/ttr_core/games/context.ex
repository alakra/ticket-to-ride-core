defmodule TtrCore.Games.Context do
  defstruct [
    id: nil,
    name: "",
    tickets: [],
    tickets_buffer: [],
    trains: [],
    routes: [],
    pieces: [],
    train_deck: nil,
    ticket_deck: nil,
    displayed_trains: [],
    other_players: [],
    longest_path_owner: nil
  ]

  alias TtrCore.Board.Route
  alias TtrCore.Games
  alias TtrCore.Cards.{
    TicketCard,
    TrainCard
  }

  defmodule OtherPlayer do
    defstruct [
      name: "",
      tickets: 0,
      trains: 0,
      pieces: 0,
      routes: [],
      track_score: 0
    ]
  end

  @type count :: integer()

  @type other_player :: %OtherPlayer{
    name: String.t,
    tickets: count(),
    trains: count(),
    pieces: count(),
    routes: [Route.t],
    track_score: count()
  }

  @type t :: %__MODULE__{
    id: Games.game_id(),
    name: String.t,
    tickets: [TicketCard.t],
    tickets_buffer: [TicketCard.t],
    trains: [TrainCard.t],
    routes: [Route.t],
    train_deck: count(),
    ticket_deck: count(),
    displayed_trains: [TrainCard.t],
    other_players: [other_player()],
    longest_path_owner: Games.user_id() | nil
  }
end
