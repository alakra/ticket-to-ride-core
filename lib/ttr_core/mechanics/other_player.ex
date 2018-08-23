defmodule TtrCore.Mechanics.OtherPlayer do
  @moduledoc false

  alias TtrCore.Board.Route

  defstruct [
    name: "",
    tickets: 0,
    trains: 0,
    pieces: 0,
    routes: [],
  ]

  @type count :: integer()

  @type t :: %__MODULE__{
    name: String.t,
    tickets: count(),
    trains: count(),
    pieces: count(),
    routes: [Route.t]
  }
end
