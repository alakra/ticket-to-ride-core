defmodule TtrCore.Mechanics.State do
  defstruct [
    id: nil,
    owner_id: nil,
    winner_id: :none,
    winner_score: 0,
    players: [],
    routes: [],
    ticket_deck: [],
    displayed_trains: [],
    train_deck: [],
    discard_deck: [],
    current_player: nil,
    stage: :unstarted,
    stage_meta: [],
    longest_path_owner: nil
  ]

  @type stage :: :unstarted | :setup | :started | :last_round | :finished
  @type meta :: list()
  @type user_id :: binary()

  @type t :: %__MODULE__{
    current_player: user_id(),
    stage: stage(),
    stage_meta: meta()
  }
end
