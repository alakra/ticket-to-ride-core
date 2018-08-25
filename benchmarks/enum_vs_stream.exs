tasks = %{
  "stream a map then sum with enum" => fn -> Stream.map(1..10000, fn x -> x * 2 end) |> Enum.sum() end,
  "enum a map then sum with enum" => fn -> Enum.map(1..10000, fn x -> x * 2 end) |> Enum.sum() end
}

Benchee.run(tasks)
