class Location < ApplicationRecord
  belongs_to :gas_station
  validates :latitude, presence: true,  uniqueness: {scope: [:longitude]}
  validates :longitude, presence: true
  before_validation :check_or_build_gas, :check_address
  # optional validations for :city, :state, postal_code

  def parse_locat_gs
    if (self.street_address && self.city && self.state && self.postal_code)
      return {'address': {
          streetAddress: self.street_address,
          city: self.city,
          state: self.state,
          postalCode: self.postal_code
        },
       'nearest_gas_station': {
         streetAddress: self.gas_station.street_address,
         city: self.gas_station.city,
         state: self.gas_station.state,
         postalCode: self.gas_station.postal_code
       }
      }
    else
      return {status: 404, message: 'No matches found'}
    end
  end

private
  def check_or_build_gas
    if self.gas_station
      return true

    elsif nearest = GasStation.where(longitude:self.longitude, latitude:self.latitude).first
      self.gas_station=nearest
      self.gas_station_id=nearest.id
      return true

    elsif nearest_gs = google_get_gas(longitude: self.longitude, latitude: self.latitude)
      if nearest_gs[:status] != 404
        output_gs = parse_and_create_gs(nearest_gs)
        self.gas_station=output_gs
        self.gas_station_id=output_gs.id
        self.save
      else
        return {status: 404}
        # raise ActionController::RoutingError.new("Gas Station for Latitude: #{self.latitude}, Longitude: #{self.longitude} Not Found.")
      end
    end
  end

  def get_addr_city_state_zip(place_id)
    return parse_addr_details(get_gplace(place_id))
  end

  def parse_addr_details(adrhash)
    for adrpiece in adrhash
      for type in adrpiece['types']
        if type == 'street_number'
          street_number = adrpiece['long_name']
        elsif type == 'route'
          street_name = adrpiece['long_name']
        elsif type == 'locality'
          city = adrpiece['long_name']
        elsif type == 'administrative_area_level_1'
          state = adrpiece['short_name']
        elsif type == 'postal_code'
          postal_code = adrpiece['long_name']
        end
      end
    end
    address = "#{street_number} #{street_name}"
    return {
      street_address: address,
      city: city,
      state: state,
      postal_code: postal_code
    }
  end

  def google_get_gas(latlnghash)
    all_gs = HTTParty.get("https://maps.googleapis.com/maps/api/place/nearbysearch/json?location=#{latlnghash[:latitude]},#{latlnghash[:longitude]}&type=gas_station&rankby=distance&key=#{ENV['APIKEY']}")
    if all_gs['results'].present?
      first_gs = all_gs['results'].first
      place_id = first_gs['place_id']
      first_gs['gas_address_details'] = get_addr_city_state_zip(place_id)
      return first_gs
    else
      return {status: 404}
    end
  end

  def check_address
    if !self.city || !self.state || !self.postal_code || self.street_address
      lookup_address = find_address_of_call(self.latitude, self.longitude)
          self.street_address = lookup_address[:street_address]
          self.city = lookup_address[:city]
          self.state = lookup_address[:state]
          self.postal_code = lookup_address[:postal_code]
    end
  end

  def parse_and_create_gs(results)
    gas_s = GasStation.find_or_create_by(latitude: self.latitude, longitude: self.longitude) do |gas|
      gas_station = results['gas_address_details']
      gas.street_address = gas_station[:street_address]
      gas.city = gas_station[:city]
      gas.state = gas_station[:state]
      gas.postal_code = gas_station[:postal_code]
    end
    return gas_s
  end

  def get_gplace(place_id)
    place_id=place_id.gsub(' ', '%20')
    place_detail_url = "https://maps.googleapis.com/maps/api/place/details/json?placeid=#{place_id}&key=#{ENV['APIKEY']}"
    place_detail_url = HTTParty.get(place_detail_url)
    return place_detail_url['result']['address_components']
  end

  def find_address_of_call(lat, lng)
    resp = HTTParty.get("https://maps.googleapis.com/maps/api/place/nearbysearch/json?location=#{lat},#{lng}&rankby=distance&key=#{ENV['APIKEY']}")
    result = resp['results'].first
    if result.present?
      place_id = result['place_id']
    else
      return {status: 404}
    end
    lookup_address = get_addr_city_state_zip(place_id)
    return lookup_address
  end

end
