# TicketToRide

## Summary

This is an implementation of Ticket to Ride (the Amercian version) in
Elixir.  It contains a multiplayer game server and a command-line
based client.

## Features

## Installation and Setup

Two environments are currently supported: `local`, `otp release` and `docker`.

### Installing locally

#### Prerequisites

### Installing with an OTP release

### Installing in a Docker container

## Playing a Game

### Running a Server

#### Starting a Game

### Joining with a Client

## Why?

### Primary Goals

I wrote this implementation of TTR so that I could experiment with
`ranch`, `msgpack` and terminal-based interactions within Elixir.

I wanted to see how well DSLs could be written with Elixir's macro
system when defining static characteristics of a turn-based game.

In TTR's case, I was able to write macros that helped me define the
graph of train routes and vathe lues of the playing cards in a very
readable way.

See [TicketToRide.Routes](lib/ticket_to_ride/routes.ex) and [TicketToRide.Tickets](lib/ticket_to_ride/tickets.ex) as
examples.

### Secondary Goals

I wanted to see how far I could push a cheap VM in the cloud to
maximize the number of connections on a single server before the
quality of service degraded.

## Development Details

### Client / Server Architecture

### OTP Architecture

### Networking Protocol Details
