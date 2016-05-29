defmodule TicketToRide.EngineTest do
  use ExUnit.Case

  alias TicketToRide.Engine

  test "engine starts" do
    {:ok, pid} = Engine.start_link
    assert Process.alive?(pid)
  end
end
