defmodule TtrCore do
  @moduledoc """
  Implementation of Ticket to Ride Game, State Management and Player Sessions
  """
  use Application

  alias TtrCore.{
    Games,
    Player
  }

  alias TtrCore.Games.{
    Index,
    Ticker,
    Turns
  }

  # API

  @doc """
  Starts the Ticket to Ride game state management and rule validation
  processes.
  """
  @spec start(Application.start_type(), start_args :: term()) :: {:ok, pid()} | {:ok, pid(), Application.state()} | {:error, reason :: term()}
  def start(_type, _args) do
    opts = [
      strategy: :one_for_one,
      name: TtrCore
    ]

    children = [
      Player.DB,
      Player.Session,
      Games,
      Ticker,
      {Registry, [keys: :unique, partitions: System.schedulers_online(), name: Index]},
      {Registry, [keys: :duplicate, partitions: System.schedulers_online(), name: Turns]}
    ]

    Supervisor.start_link(children, opts)
  end
end
