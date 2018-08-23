defmodule TtrCore.Mechanics.Context do
  @moduledoc false

  alias TtrCore.Mechanics.OtherPlayer
  alias TtrCore.Board.Route
  alias TtrCore.Games
  alias TtrCore.Cards.{
    TicketCard,
    TrainCard
  }

  defstruct [
    id: "",
    game_id: "",
    name: "",
    stage: :unstarted,
    tickets: [],
    tickets_buffer: [],
    trains: [],
    routes: [],
    pieces: 45,
    train_deck: 0,
    trains_selected: 0,
    ticket_deck: [],
    displayed_trains: [],
    current_player: "",
    other_players: [],
    longest_path_owner: ""
  ]

  @type count :: integer()

  @type t :: %__MODULE__{
    id: Games.user_id(),
    game_id: Games.game_id(),
    name: String.t,
    tickets: [TicketCard.t],
    tickets_buffer: [TicketCard.t],
    trains: [TrainCard.t],
    trains_selected: count(),
    routes: [Route.t],
    train_deck: count(),
    ticket_deck: count(),
    displayed_trains: [TrainCard.t],
    current_player: Game.user_id(),
    other_players: [OtherPlayer.t],
    longest_path_owner: Games.user_id() | nil
  }
end
