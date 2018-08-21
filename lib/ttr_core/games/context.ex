defmodule TtrCore.Games.Context do
  @moduledoc false

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

  alias TtrCore.Board.Route
  alias TtrCore.Games
  alias TtrCore.Cards.{
    TicketCard,
    TrainCard
  }

  defmodule OtherPlayer do
    @moduledoc false

    defstruct [
      name: "",
      tickets: 0,
      trains: 0,
      pieces: 0,
      routes: [],
    ]
  end

  @type count :: integer()

  @type other_player :: %OtherPlayer{
    name: String.t,
    tickets: count(),
    trains: count(),
    pieces: count(),
    routes: [Route.t]
  }

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
    other_players: [other_player()],
    longest_path_owner: Games.user_id() | nil
  }
end
