class AddGasStationRefToLocation < ActiveRecord::Migration[5.1]
  def change
    add_reference :locations, :gas_station, foreign_key: true
  end
end
