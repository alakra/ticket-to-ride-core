defmodule TtrCore.Players.Session do
  @moduledoc false

  # TBD: Change this to use con_cache with expiration support

  alias TtrCore.Players.DB

  defstruct [:user_id, :name, :token, :expiration]

  @type t :: %__MODULE__{
    user_id: id(),
    name: String.t,
    token: id(),
    expiration: DateTime.t
  }

  @type user_id :: binary
  @type username :: String.t
  @type password :: String.t
  @type id :: binary

  # TBD: Change this API to accept an customizable expiration for all
  # sessions

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

  @spec active?(t) :: boolean()
  def active?(%{expiration: expiration}) do
    now = DateTime.utc_now()
    DateTime.compare(now, expiration) == :lt
  end

  @spec find_active((t -> any())) :: [t]
  def find_active(fun) do
    __MODULE__
    |> Agent.get(&Map.values(&1))
    |> Enum.filter(&active?(&1))
    |> Enum.map(&fun.(&1))
  end

  @spec create(username(), password()) :: {:ok, t} | {:error, :user_not_found | :incorrect_password}
  def create(username, password) do
    case DB.validate(username, password) do
      {:error, msg} ->
        {:error, msg}
      user ->
        session = generate_session(user)
        store_session!(session)
        {:ok, session}
    end
  end

  @spec destroy(user_id()) :: :ok
  def destroy(user_id) do
    Agent.update(__MODULE__, &Map.delete(&1, user_id))
  end

  # Private

  defp store_session!(session) do
    Agent.update(__MODULE__, &Map.put(&1, session.user_id, session))
  end

  defp generate_session(user) do
    token = 32
    |> :crypto.strong_rand_bytes()
    |> Base.encode64()

    %__MODULE__{
      user_id: user.id,
      name: user.username,
      token: token,
      expiration: generate_expiration()
    }
  end

  defp generate_expiration do
    DateTime.utc_now()
    |> DateTime.to_naive()
    |> NaiveDateTime.add(60 * 60 * 24, :second)
    |> DateTime.from_naive!("Etc/UTC")
  end
end
