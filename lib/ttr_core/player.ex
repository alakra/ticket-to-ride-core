defmodule TtrCore.Player do
  defstruct [
    id: 1,
    name: "anonymous",
    pieces: 45,
    tickets: [],
    trains: [],
    routes: [],
    track_score: 1
  ]
end
