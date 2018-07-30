defmodule TtrCore.Player.DB do
  @moduledoc """
  An `Agent` process that manages all players.

  NOTE: Does not currently persist between restarts.
  """

  alias TtrCore.User

  @type reason() :: String.t
  @type username() :: String.t
  @type password() :: String.t

  # API

  @doc """
  Starts the `TtrCore.Player.DB` as an `Agent` process.
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

  def get(:username, username) do
    Agent.get(__MODULE__, &Map.get(&1, username))
  end

  # TODO: Fix with another map that has an index of ids
  def get(:id, id) do
    Agent.get(__MODULE__, &Enum.find(&1, fn {_,v} -> v.id == id end))
  end

  @doc """
  Registers username with password into the player database. If the
  user already exists, then an `{:error, reason}` tuple is returned.

  NOTE: This is not currently persistent between restarts.
  """
  @spec register(username(), password()) :: :ok | {:error, reason()}
  def register(username, password) do
    existing_user = get(:username, username)

    case existing_user do
      nil ->
        user = %User{id: UUID.uuid1(:hex), username: username, password: password}
        Agent.update(__MODULE__, &Map.put(&1, username, user))
        :ok
      _ ->
        {:error, "User already registered."}
    end
  end

  def validate(username, pass) do
    get(:username, username)
    |> has_valid_record
    |> has_valid_pass(pass)
  end

  # Private

  defp has_valid_record(record) do
    if record do
      record
    else
      {:error, "User does not exist."}
    end
  end

  defp has_valid_pass({:error, error}, _), do: {:error, error}
  defp has_valid_pass(record, password) do
    if record.password == password do
      record
    else
      {:error, "Password does not match."}
    end
  end
end
