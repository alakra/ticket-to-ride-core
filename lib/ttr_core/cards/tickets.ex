defmodule TtrCore.Cards.Tickets do
  @moduledoc false

  use TtrCore.Cards.Conductor

  defticket Denver,         to: El.Paso,        value: 4
  defticket Kansas.City,    to: Houston,        value: 5
  defticket New.York,       to: Atlanta,        value: 6

  defticket Calgary,        to: Salt.Lake.City, value: 7
  defticket Chicago,        to: New.Orleans,    value: 7

  defticket Helena,         to: Los.Angeles,    value: 8
  defticket Sault.St.Marie, to: Nashville,      value: 8
  defticket Duluth,         to: Houston,        value: 8

  defticket Montreal,       to: Atlanta,        value: 9
  defticket Seattle,        to: Los.Angeles,    value: 9
  defticket Chicago,        to: Sante.Fe,       value: 9
  defticket Sault.St.Marie, to: Oklahoma.City,  value: 9

  defticket Toronto,        to: Miami,          value: 10
  defticket Duluth,         to: El.Paso,        value: 10

  defticket Winnipeg,       to: Little.Rock,    value: 11
  defticket Dallas,         to: New.York,       value: 11
  defticket Portland,       to: Phoenix,        value: 11
  defticket Denver,         to: Pittsburgh,     value: 11

  defticket Boston,         to: Miami,          value: 12
  defticket Winnipeg,       to: Houston,        value: 12

  defticket Vancouver,      to: Sante.Fe,       value: 13
  defticket Montreal,       to: New.Orleans,    value: 13
  defticket Calgary,        to: Phoenix,        value: 13

  defticket Los.Angeles,    to: Chicago,        value: 16

  defticket Portland,       to: Nashville,      value: 17
  defticket San.Francisco,  to: Atlanta,        value: 17

  defticket Vancouver,      to: Montreal,       value: 20
  defticket Los.Angeles,    to: Miami,          value: 20
  defticket Los.Angeles,    to: New.York,       value: 21
  defticket Seattle,        to: New.York,       value: 22
end
