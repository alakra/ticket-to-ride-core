defmodule TtrCore.Player.Session do
  @moduledoc """
  Maintains player sessions that are connected to the game. Used to
  identify and track players with games.
  """
  alias TtrCore.Player.DB

  defstruct [:user_id, :name, :token, :expiration]

  @type t :: %__MODULE__{
    user_id: uuid(),
    name: String.t,
    token: uuid(),
    expiration: DateTime.t
  }

  @type username :: String.t
  @type password :: String.t
  @type uuid :: String.t
  @type reason :: String.t

  @doc """
  Starts the `TtrCore.Player.Session` as an `Agent` process.
  """
  @spec start_link() :: {:ok, pid()}
  def start_link do
    Agent.start_link(fn -> Map.new end, name: __MODULE__)
  end

  @doc """
  Specifies `TtrCore.Player.DB` to run as a worker.
  """
  @spec child_spec(term) :: Supervisor.child_spec()
  def child_spec(_) do
    %{id: __MODULE__,
      start: {__MODULE__, :start_link, []},
      type: :worker}
  end

  @doc """
  Creates a new session (login) for a user. Returns a token that is
  used to track a user's relationship to a game.
  """
  @spec new(username(), password()) :: {:ok, t} | {:error, reason}
  def new(username, pass) do
    case DB.validate(username, pass) do
      {:error, msg} ->
        {:error, msg}
      user ->
        session = generate_session(user)
        store_session!(session)
        {:ok, session}
    end
  end

  @doc """
  Gets an existing session with a token.
  """
  @spec get(uuid()) :: {:ok, t} | {:error, :not_found}
  def get(token) do
    session = Agent.get(__MODULE__, fn map ->
      Enum.find(map, fn {k, _} -> k == token end)
    end)

    case session do
      {_token, session} -> {:ok, session}
      nil -> {:error, :not_found}
    end
  end

  @doc """
  Get all sessions.
  """
  @spec all() :: [t]
  def all do
    Agent.get(__MODULE__, &(&1))
  end

  # Private

  defp store_session!(session) do
    Agent.update(__MODULE__, &Map.put(&1, session.token, session))
  end

  defp generate_session(user) do
    %__MODULE__{user_id: user.id, name: user.username, token: UUID.uuid1(:hex), expiration: nil}
  end
end
