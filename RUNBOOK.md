# Runbook


## Create a user and game with that user
{:ok, :registered} = TicketToRide.Client.register("user", "pass")
{:ok, token} = TicketToRide.Client.login("user", "pass")
{:ok, game_id} = TicketToRide.Client.create(token, [])

## Check a list
TicketToRide.Client.list
