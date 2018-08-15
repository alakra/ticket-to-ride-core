defmodule TtrCore.Board.Routes do
  @moduledoc false

  use TtrCore.Board.Router

  defroute Atlanta,        to: Charleston,     distance: 2
  defroute Atlanta,        to: Miami,          distance: 5, trains: [:passenger]
  defroute Atlanta,        to: Raleigh,        distance: 2, trains: [:any, :any]
  defroute Atlanta,        to: Nashville,      distance: 1
  defroute Atlanta,        to: New.Orleans,    distance: 4, trains: [:box, :tanker]

  defroute Boston,         to: Montreal,       distance: 2, trains: [:any, :any]
  defroute Boston,         to: New.York,       distance: 1, trains: [:coal, :box]

  defroute Calgary,        to: Vancouver,      distance: 3
  defroute Calgary,        to: Seattle,        distance: 4
  defroute Calgary,        to: Helena,         distance: 4
  defroute Calgary,        to: Winnipeg,       distance: 6, trains: [:reefer]

  defroute Charleston,     to: Raleigh,        distance: 2
  defroute Charleston,     to: Miami,          distance: 4, trains: [:freight]

  defroute Chicago,        to: Pittburgh,      distance: 3, trains: [:tanker, :hopper]
  defroute Chicago,        to: Toronto,        distance: 4, trains: [:reefer]
  defroute Chicago,        to: Duluth,         distance: 3, trains: [:coal]
  defroute Chicago,        to: Omaha,          distance: 4, trains: [:passenger]
  defroute Chicago,        to: St.Louis,       distance: 2, trains: [:caboose, :reefer]

  defroute Dallas,         to: Little.Rock,    distance: 2
  defroute Dallas,         to: Houston,        distance: 1, trains: [:any, :any]
  defroute Dallas,         to: Oklahoma.City,  distance: 2, trains: [:any, :any]
  defroute Dallas,         to: El.Paso,        distance: 4, trains: [:coal]

  defroute Denver,         to: Kansas.City,    distance: 4, trains: [:tanker, :hopper]
  defroute Denver,         to: Omaha,          distance: 4, trains: [:freight]
  defroute Denver,         to: Helena,         distance: 4, trains: [:caboose]
  defroute Denver,         to: Salt.Lake.City, distance: 3, trains: [:coal, :box]
  defroute Denver,         to: Phoenix,        distance: 5, trains: [:reefer]
  defroute Denver,         to: Sante.Fe,       distance: 2
  defroute Denver,         to: Oklahoma.City,  distance: 4, trains: [:coal]

  defroute Duluth,         to: Winnipeg,       distance: 4, trains: [:hopper]
  defroute Duluth,         to: Sault.St.Marie, distance: 3
  defroute Duluth,         to: Toronto,        distance: 6, trains: [:freight]
  defroute Duluth,         to: Omaha,          distance: 2, trains: [:any, :any]
  defroute Duluth,         to: Helena,         distance: 6, trains: [:tanker]

  defroute El.Paso,        to: Sante.Fe,       distance: 2
  defroute El.Paso,        to: Oklahoma.City,  distance: 5, trains: [:box]
  defroute El.Paso,        to: Houston,        distance: 4, trains: [:coal]
  defroute El.Paso,        to: Los.Angeles,    distance: 6, trains: [:hopper]
  defroute El.Paso,        to: Phoenix,        distance: 3

  defroute Helena,         to: Winnipeg,       distance: 4, trains: [:passenger]
  defroute Helena,         to: Omaha,          distance: 5, trains: [:coal]
  defroute Helena,         to: Salt.Lake.City, distance: 3, trains: [:freight]
  defroute Helena,         to: Seattle,        distance: 6, trains: [:box]

  defroute Houston,        to: New.Orleans,    distance: 2

  defroute Kansas.City,    to: Omaha,          distance: 1
  defroute Kansas.City,    to: St.Louis,       distance: 2, trains: [:passenger, :freight]
  defroute Kansas.City,    to: Oklahoma.City,  distance: 2, trains: [:any, :any]

  defroute Las.Vegas,      to: Los.Angeles,    distance: 2
  defroute Las.Vegas,      to: Salt.Lake.City, distance: 3, trains: [:tanker]

  defroute Little.Rock,    to: St.Louis,       distance: 2
  defroute Little.Rock,    to: Nashville,      distance: 3, trains: [:reefer]
  defroute Little.Rock,    to: New.Orleans,    distance: 3, trains: [:caboose]
  defroute Little.Rock,    to: Oklahoma.City,  distance: 2

  defroute Los.Angeles,    to: San.Francisco,  distance: 3, trains: [:box, :freight]
  defroute Los.Angeles,    to: Las.Vegas,      distance: 2
  defroute Los.Angeles,    to: Phoenix,        distance: 3

  defroute Miami,          to: New.Orleans,    distance: 6

  defroute Montreal,       to: Toronto,        distance: 3
  defroute Montreal,       to: Sault.St.Marie, distance: 5, trains: [:hopper]
  defroute Montreal,       to: New.York,       distance: 3, trains: [:passenger]

  defroute Nashville,      to: Pittsburgh,     distance: 4, trains: [:box]
  defroute Nashville,      to: Raleigh,        distance: 3, trains: [:hopper]
  defroute Nashville,      to: St.Louis,       distance: 2

  defroute New.York,       to: Pittsburgh,     distance: 2, trains: [:reefer, :caboose]
  defroute New.York,       to: Washington,     distance: 2, trains: [:tanker, :hopper]

  defroute Oklahoma.City,  to: Sante.Fe,       distance: 3, trains: [:passenger]

  defroute Phoenix,        to: Sante.Fe,       distance: 3

  defroute Pittsburgh,     to: Toronto,        distance: 2
  defroute Pittsburgh,     to: Washington,     distance: 2
  defroute Pittsburgh,     to: Raleigh,        distance: 2
  defroute Pittsburgh,     to: St.Louis,       distance: 5, trains: [:caboose]

  defroute Portland,       to: Seattle,        distance: 1
  defroute Portland,       to: Salt.Lake.City, distance: 6, trains: [:passenger]
  defroute Portland,       to: San.Francisco,  distance: 5, trains: [:freight, :caboose]

  defroute Raleigh,        to: Washington,     distance: 2, trains: [:any, :any]

  defroute Salt.Lake.City, to: San.Francisco,  distance: 5, trains: [:tanker, :reefer]

  defroute Sault.St.Marie, to: Winnipeg,       distance: 6
  defroute Sault.St.Marie, to: Toronto,        distance: 2

  defroute Seattle,        to: Vancouver,      distance: 1, trains: [:any, :any]
end
