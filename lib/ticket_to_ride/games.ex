defmodule TicketToRide.Games do
  use Supervisor

  alias TicketToRide.Game
  alias TicketToRide.Games.Index

  require Logger

  # API

  def start_link do
    Supervisor.start_link(__MODULE__, [], [name: __MODULE__])
  end

  def init(_args) do
    children = [
      worker(Game, [], restart: :transient)
    ]

    supervise(children, strategy: :simple_one_for_one)
  end

  def list do
    {:ok, Index.all |> Map.keys}
  end

  def create(options) do
    case Supervisor.start_child(__MODULE__, [options]) do
      {:ok, game} -> {:ok, Game.id(game) |> Index.put(game)}
      {:error, error} -> {:error, error}
    end
  end

  def join(game_id, user_session) do
    case Index.get(game_id) do
      {:ok, game} -> Game.join(game, user_session)
      :error -> {:error, :not_found}
    end
  end

  def leave(game_id, user_session) do
    case Index.get(game_id) do
      {:ok, game} -> Game.leave(game, user_session)
      :error -> {:error, :not_found}
    end
  end

  def destroy(game) do
    case Supervisor.terminate_child(__MODULE__, game) do
      :ok -> :ok
      {:error, :not_found} ->
        Logger.warn("Tried to destroy game, #{game}, but it doesn't exist.")
        :ok
    end
  end
end
