defmodule TtrCore.Players.User do
  @moduledoc false

  defstruct [
    :id,
    :username,
    :password
  ]

  @type id :: binary()

  @type t :: %__MODULE__{
    id: id(),
    username: String.t,
    password: binary(),
  }
end
