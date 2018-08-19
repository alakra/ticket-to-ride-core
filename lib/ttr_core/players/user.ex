defmodule TtrCore.Players.User do
  @moduledoc false

  defstruct [
    :id,
    :username,
    :password
  ]

  @type t :: %__MODULE__{
    id: String.t,
    username: String.t,
    password: String.t,
  }
end
