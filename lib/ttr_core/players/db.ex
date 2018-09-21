defmodule TtrCore.Players.DB do
  @moduledoc false

  alias TtrCore.Players.User

  @type user_id :: binary
  @type username() :: String.t
  @type password() :: String.t

  # API

  @spec start_link() :: {:ok, pid()}
  def start_link do
    Agent.start_link(fn -> Map.new end, name: __MODULE__)
  end

  @spec child_spec(term) :: Supervisor.child_spec()
  def child_spec(_) do
    %{id: __MODULE__,
      start: {__MODULE__, :start_link, []},
      type: :worker}
  end

  @spec find_by_username(username) :: User.t | :user_not_found
  def find_by_username(username) do
    Agent.get(__MODULE__, &Map.get(&1, username, :user_not_found))
  end

  @spec find_users([user_id()]) :: [User.t]
  def find_users(user_ids) do
    __MODULE__
    |> Agent.get(&Map.values(&1))
    |> Enum.filter(&Enum.member?(user_ids, &1.id))
  end

  @spec register(username(), password()) :: {:ok, user_id()} | {:error, :already_registered}
  def register(username, password) do
    case find_by_username(username) do
      :user_not_found ->
        user_id = :crypto.strong_rand_bytes(32) |> Base.encode64()

        user =
          %User{
            id: user_id,
            username: username,
            password: password
          }

        Agent.update(__MODULE__, &Map.put(&1, username, user))

        {:ok, user_id}
      _ ->
        {:error, :already_registered}
    end
  end

  @spec validate(username(), password()) :: User.t | {:error, :user_not_found | :incorrect_password}
  def validate(username, password) do
    username
    |> find_by_username()
    |> has_valid_pass(password)
  end

  @spec get_all_users() :: [User.t]
  def get_all_users do
    Agent.get(__MODULE__, &Map.values(&1))
  end

  # Private

  defp has_valid_pass(:user_not_found, _), do: {:error, :user_not_found}
  defp has_valid_pass(record, password) do
    if record.password == password do
      record
    else
      {:error, :incorrect_password}
    end
  end
end
