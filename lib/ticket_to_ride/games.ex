defmodule TicketToRide.Games do
  use Supervisor

  alias TicketToRide.Game
  alias TicketToRide.Game.Index

  require Logger

  # API

  def start_link do
    Supervisor.start_link(__MODULE__, [], [name: __MODULE__])
  end

  # Callbacks

  def init(_args) do
    children = [
      worker(Game, [], restart: :transient)
    ]

    supervise(children, strategy: :simple_one_for_one)
  end

  def list do
    {:ok, Index.all(:ids)}
  end

  def create(options) do
    id = UUID.uuid1(:hex)
    opts = Keyword.put(options, :id, id)

    case Supervisor.start_child(__MODULE__, [opts]) do
      {:ok, game} -> {:ok, Index.put(id, game, %{})}
      {:error, error} -> {:error, error}
    end
  end

  def begin(game_id, owner_id) do
    # TODO: Do check for games that have already been started
    case Index.get(game_id) do
      {:ok, {_, game, _}} ->
        Logger.info("Game starting #{game_id}")
        Game.begin(game, owner_id)
      :error ->
        {:error, :not_found}
    end
  end

  def join(game_id, user_id) do
    case Index.get(game_id) do
      {:ok, {_, game, _}} -> Game.join(game, user_id)
      :error -> {:error, :not_found}
    end
  end

  def leave(game_id, user_id) do
    case Index.get(game_id) do
      {:ok, {_, game, _}} -> Game.leave(game, user_id)
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
