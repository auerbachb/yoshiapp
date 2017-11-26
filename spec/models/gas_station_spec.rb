require 'rails_helper'

RSpec.describe GasStation, type: :model do
  test_params = {latitude: '1234', longitude: '5678',
    street_address: '1234 Fake Street', city: 'San Francisco', state: 'CA', postal_code:'94118'}
  let(:gas_station) {GasStation.new(test_params)}
  before { @loc = gas_station.location}


    it "should not create a gas station if required attributes are missing" do
        @gas = GasStation.create()
        expect(GasStation.all.count).to eq(0)
    end

    it "should create a gas station if latitude, longitude and address details are present" do
      @gas = GasStation.new(test_params)
      @gas.save()
      expect(GasStation.all.count).to eq(1)
    end

end
