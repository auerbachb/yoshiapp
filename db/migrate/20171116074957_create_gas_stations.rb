class CreateGasStations < ActiveRecord::Migration[5.1]
  def change
    create_table :gas_stations do |t|
      t.string :street_address
      t.string :city
      t.string :state
      t.string :postal_code
      t.string :latitude
      t.string :longitude

      t.timestamps
    end
  end
end
