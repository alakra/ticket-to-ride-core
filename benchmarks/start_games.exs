alias TtrCore.{
  Games,
  Players
}

{:ok, _} = Players.register("player_a", "P@ssw0rd!")
{:ok, session_a} = Players.login("player_a", "P@ssw0rd!")

{:ok, _} = Players.register("player_b", "P@ssw0rd!")
{:ok, session_b} = Players.login("player_a", "P@ssw0rd!")

create_fun = fn _ ->
  {:ok, _, _} = Games.create(session_a.user_id)
end

Benchee.run(%{
  "start 1 game" => fn -> create_fun.(:ok) end,
  "start 100 games" => fn -> Enum.each(1..100, create_fun) end,
  "start 1000 games" => fn -> Enum.each(1..1000, create_fun) end,
  "start 10000 games" => fn -> Enum.each(1..10000, create_fun) end,
  "start 100000 games" => fn -> Enum.each(1..100000, create_fun) end
}, memory_time: 2)
