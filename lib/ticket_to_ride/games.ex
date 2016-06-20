defmodule TicketToRide.Games do
  use Supervisor

  alias TicketToRide.Game

  require Logger

  # API

  def start_link do
    Supervisor.start_link(__MODULE__, [name: __MODULE__])
  end

  def init([]) do
    children = [
      worker(Game, [], restart: :transient)
    ]

    supervise(children, strategy: :simple_one_for_one)
  end

  def create(user, options) do
    Supervisor.start_child(__MODULE__, [[user: user, options: options]])
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
