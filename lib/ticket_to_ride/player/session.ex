defmodule TicketToRide.Player.Session do
  alias TicketToRide.Player.DB

  defstruct [:id, :name, :token, :expiration]

  def start_link do
    Agent.start_link(fn -> Map.new end, name: __MODULE__)
  end

  def new(username, pass) do
    case DB.validate(username, pass) do
      user ->
        user
        |> generate_session
        |> store_session
      {:error, msg} ->
        {:error, msg}
    end
  end

  def get(token) do
    session = Agent.get(__MODULE__, fn map ->
      Enum.find(map, fn {k, _} -> k == token end)
    end)

    case session do
      {token, session} -> {:ok, session}
      nil -> {:error, :not_found}
    end
  end

  def all do
    Agent.get(__MODULE__, &(&1))
  end

  # Private

  defp store_session(session) do
    Agent.update(__MODULE__, &Map.put(&1, session.token, session))
    {:ok, session}
  end

  defp generate_session(user) do
    %__MODULE__{id: user.id, name: user.username, token: UUID.uuid1(:hex), expiration: nil}
  end
end
