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
