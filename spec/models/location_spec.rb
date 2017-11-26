require "rails_helper"

RSpec.describe Location, type: :model do

  gas_params = {latitude: "1234", longitude: "5678",
    street_address: "1234 Fake Street", city: "San Francisco", state: "CA", postal_code:"94118"}
  let(:gas_station) {GasStation.new(gas_params)}
  before { @loc = gas_station.location}
  subject { @loc = gas_station.location}

  context "validating and creating a location" do
    it "is not valid without a latitude" do
      @loc2 = Location.new(longitude:"long", gas_station: gas_station)
      expect(Location.new()).to be_invalid
    end

    it "is not valid without an associated GasStation" do
      expect(Location.new(latitude:"lat",longitude:"long")).to be_invalid
    end

    it "is valid only with latitude, longitude attributes and associated GasStation" do
        expect(Location.new(latitude:"lat",longitude:"long")).to be_invalid
        expect(Location.new(latitude:"lat",longitude:"long", gas_station: gas_station)).to be_valid
    end

    it "it saves with latitude, longitude and associated gas station object" do
      @newloc = Location.create(latitude: "123.456", longitude: "7891011", gas_station: gas_station)
      expect(Location.all.count).to eq(1)
    end
  end

  context "private methods" do
    it "is valid only if all address components are present" do
      @private_loc = Location.new(latitude:"lat",longitude:"long", gas_station: gas_station)
      resp =  @private_loc.send(:parse_locat_gs)
      expect(resp[:status]).to eq(404)
      expect(resp[:message]).to eq("No matches found")
    end

    it "should return a json output if all attributes of location and associated gas station are present" do
      loc_params = {latitude: "47.221101", longitude: "31.362412",
        street_address: "12 Ross Alley", city: "San Francisco", state: "CA", postal_code:"94108"}

      @private_gas = gas_station
      @private_loc = Location.new(loc_params)
      @private_loc.gas_station = @private_gas
      resp = @private_loc.send(:parse_locat_gs)
      expect(resp[:address][:streetAddress]).to eq("12 Ross Alley")
      expect(resp[:address][:city]).to eq("San Francisco")
      expect(resp[:nearest_gas_station][:streetAddress]).to eq("1234 Fake Street")
      expect(resp[:nearest_gas_station][:city]).to eq("San Francisco")
    end
  end
end
