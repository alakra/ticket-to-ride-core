# Core Usage (after application startup)

:ok = TtrCore.Player.DB.register("playerA", "p@ssw0rd!")
{:ok, sessionA} = TtrCore.Player.Session.new("playerA", "p@ssw0rd!")

:ok = TtrCore.Player.DB.register("playerB", "p@ssw0rd!")
{:ok, sessionB} = TtrCore.Player.Session.new("playerB", "p@ssw0rd!")

{:ok, id, pid} = TtrCore.Games.create(sessionA.user_id)
{:ok, ids} = TtrCore.Games.list()

:ok = TtrCore.Games.join(id, sessionB.user_id)

:ok = TtrCore.Games.begin(id, sessionA.user_id)

:ok = TtrCore.Games.leave(id, sessionB.user_id)
:ok = TtrCore.Games.leave(id, sessionA.user_id)



# Quick and Dirty

```
{:ok, :registered} = TicketToRide.Client.register("user_a", "pass")
{:ok, token_a} = TicketToRide.Client.login("user_a", "pass")
{:ok, game_id} = TicketToRide.Client.create(token_a, [])
{:ok, :registered} = TicketToRide.Client.register("user_b", "pass")
{:ok, token_b} = TicketToRide.Client.login("user_b", "pass")
{:ok, {:joined, _}} = TicketToRide.Client.join(token_b, game_id)
{:ok, :began} = TicketToRide.Client.begin(token_a, game_id)
```

# Full Runbook

## Create a user and game with that user

```
{:ok, :registered} = TicketToRide.Client.register("user_a", "pass")
{:ok, token_a} = TicketToRide.Client.login("user_a", "pass")
{:ok, game_id} = TicketToRide.Client.create(token_a, [])
```

## Check a list

```
{:ok, [first|remainder]} = TicketToRide.Client.list
```

## Create another user

```
{:ok, :registered} = TicketToRide.Client.register("user_b", "pass")
{:ok, token_b} = TicketToRide.Client.login("user_b", "pass")
```

## Join a specific game

```
{:ok, {:joined, _}} = TicketToRide.Client.join(token_b, game_id)
```

## Leave a specific game

```
{:ok, :left} = TicketToRide.Client.leave(token_b, game_id)
{:ok, :left} = TicketToRide.Client.leave(token_a, game_id)
```

## Join first available game

```
{:ok, {:joined, actual_id}} = TicketToToRide.Client.join(token_b, :any)
```

## Start game

```
{:ok, :began} = TicketToRide.Client.begin(token_a, game_id)
```
