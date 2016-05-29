defmodule TicketToRide do
  use Application

  import Supervisor.Spec

  alias TicketToRide.{Client, Server, CLI, Interface}

  # API

  def start(_type, args) do
    opts = [
      strategy: :one_for_one,
      name: TicketToRide
    ]

    real_args = Application.get_env(:ticket_to_ride, :options, args)
    Supervisor.start_link(children(real_args), opts)
  end

  # Private

  defp children(options) do
    server = options[:server]
    limit  = options[:limit]
    ip     = options[:ip]
    port   = options[:port]

    if server do
      [worker(Server, [[limit: limit, ip: ip, port: port]], restart: :permanent)]
    else
      [worker(Client, [[ip: ip, port: port]], restart: :transient),
       worker(Interface, [], restart: :transient)]
    end
  end
end
