defmodule TicketToRide.Player.DB do
  # TODO: Persist this data in Mnesia

  def start_link do
    Agent.start_link(fn -> Map.new end, name: __MODULE__)
  end

  def register(user, pass) do
    existing_user = Agent.get(__MODULE__, &Map.get(&1, user))

    case existing_user do
      nil ->
        Agent.update(__MODULE__, &Map.put(&1, user, %{pass: pass, token: nil}))
        :ok
      _ ->
        {:error, "User already registered."}
    end
  end

  def login(user, pass) do
    Agent.get(__MODULE__, &Map.get(&1, user))
    |> has_valid_record
    |> has_valid_pass(pass)
    |> generate_token
    |> update_record(user)
  end

  # Private

  defp has_valid_record(record) do
    if record do
      record
    else
      {:error, "User does not exist."}
    end
  end

  # TODO: Use a secure password checking mechanism
  defp has_valid_pass({:error, error}, _), do: {:error, error}
  defp has_valid_pass(record, pass) do
    if record.pass == pass do
      record
    else
      {:error, "Password does not match."}
    end
  end

  defp generate_token({:error, error}), do: {:error, error}
  defp generate_token(record), do: %{record | token: UUID.uuid1(:hex)}

  defp update_record({:error, error}, _), do: {:error, error}
  defp update_record(record, user) do
    Agent.update(__MODULE__, &Map.put(&1, user, record))
    {:ok, record.token}
  end
end
