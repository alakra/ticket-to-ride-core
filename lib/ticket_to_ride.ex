defmodule TicketToRide do
  @moduledoc """
  ## Summary

  `TicketToRide` is an application that implements the board game,
  Ticket to Ride.  It provides a TCP client and server implementation
  and can support mulitple games and players within a single server
  instance.

  ## Configuration

  Depending on what options are set in the `Mix.Config` for the loaded
  environment, one can start a server or a client.

  ### Server Mode

  In order to start as a server, the application env for
  `:ticket_to_ride` must be:

  ```
  use Mix.Config

  config :ticket_to_ride, :options,
    server: true,
    limit: 1000,
    ip: "127.0.0.1",
    port: 7777
  ```

  The `limit` option is used to limit the maximum number of
  connections.  The default is 1000 connections.

  This is automatically done by the mix task, `mix ttr.server`. There
  is no need to do this manually unless you are doing development.

  ### Client Mode

  In order to start as a client, the application env for
  `:ticket_to_ride` must be:

  ```
  use Mix.Config

  config :ticket_to_ride, :options,
    ip: "127.0.0.1",
    port: 7777
  ```

  This is automatically done by the mix task, `mix ttr.client`. There
  is no need to do this manually unless you are doing development.
  """

  use Application

  import Supervisor.Spec

  alias TicketToRide.{
    Player,
    Client,
    Games,
    Game,
    Server,
    Interface
  }

  # API

  @doc """
  Starts the `TicketToRide` application as a client or server.
  """
  @spec start(Application.start_type(), start_args :: term()) ::
  {:ok, pid()}
  | {:ok, pid(), Application.state()}
  | {:error, reason :: term()}
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
      [worker(Server, [[limit: limit, ip: ip, port: port]], restart: :permanent),
       worker(Player.DB, [], restart: :permanent),
       worker(Player.Session, [], restart: :permanent),
       worker(Game.Index, [], restart: :permanent),
       supervisor(Games, [], restart: :permanent)]
    else
      [worker(Client, [[ip: ip, port: port]], restart: :transient),
       worker(Interface, [], restart: :transient)]
    end
  end
end
