defmodule TicketToRide.TrainCard do
  @car_counts [
    box: 12,
    passenger: 12,
    tanker: 12,
    reefer: 12,
    freight: 12,
    hopper: 12,
    coal: 12,
    caboose: 12,
    locomotive: 12
  ]

  defstruct [
    type: nil
  ]

  def breakdown do
    @car_counts
  end
end
