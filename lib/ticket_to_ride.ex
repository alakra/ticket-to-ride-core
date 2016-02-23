defmodule TicketToRide do
  use Application

  alias TicketToRide.Engine

  def start(_type, _args) do
    import Supervisor.Spec

    children = [
      worker(Engine, [[name: TicketToRide.Engine ]])
    ]

    opts = [
      strategy: :one_for_one,
      name: TicketToRide
    ]

    Supervisor.start_link(children, opts)
  end
end
