defmodule TtrCore.Games.MachineTest do
  use ExUnit.Case, async: true

  alias TtrCore.Player
  alias TtrCore.Games.{
    Machine,
    State
  }

  setup do
    owner = %Player{id: "123"}
    state = %State{owner_id: owner.id, players: [owner]}

    {:ok, owner: owner, state: state}
  end

  describe "can_begin?/2" do
    test "returns success if the game can begin", %{state: state, owner: owner} do
      player_id = "456"
      new_state = Machine.add_player(state, player_id)

      assert :ok == Machine.can_begin?(new_state, owner.id)
    end

    test "returns error if the game has already started", %{state: state, owner: owner} do
      player_id = "456"
      new_state = Machine.add_player(state, player_id)

      assert :ok == Machine.can_begin?(new_state, owner.id)
      {:ok, begun_state} = Machine.begin_game(new_state)

      assert {:error, :already_started} == Machine.can_begin?(begun_state, owner.id)
    end

    test "returns error if the player passed in cannot start the game (because player is not owner of game)", %{state: state} do
      player_id = "456"
      new_state = Machine.add_player(state, player_id)

      assert {:error, :not_owner} == Machine.can_begin?(new_state, "XYZ")
    end

    test "returns error if there is not enough players to start the game", %{state: state, owner: owner} do
      assert {:error, :not_enough_players} == Machine.can_begin?(state, owner.id)
    end
  end
end
