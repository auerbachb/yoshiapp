class LocationController < ApplicationController
  def find_nearest_gs
    lat = params[:lat]
    lng = params[:lng]
    location = Location.where(latitude: lat, longitude: lng).first
    if location
      return render :json => parse_locat_gs(location)
    else
      gas_address = nearest_gas(lat, lng)
      lookup_address = find_address_of_call(lat, lng)
    end
    return render :json => {gas_address: gas_address['gas_address_details'], lookup_address: lookup_address}

  end


  def parse_locat_gs(location)
    {'address': {
        streetAddress: location.street_address,
        city: location.city,
        state: location.state,
        postalCode: location.postal_code
      },
     'nearest_gas_station': {
       streetAddress: location.gas_station.street_address,
       city: location.gas_station.city,
       state: location.gas_station.state,
       postalCode: location.gas_station.postal_code
     }
    }
  end

  def temp_gas
    return render :json => nearest_gas(params[:lat], params[:lng])
  end

  def find_address
    return render :json => find_address_of_call(params[:lat], params[:lng])
  end

  private

  def nearest_gas(lat, lng)
    #return "https://maps.googleapis.com/maps/api/place/nearbysearch/json?location=#{lat},#{lng}&type=gas_station&rankby=distance&key=#{ENV['APIKEY']}"
    resp = HTTParty.get("https://maps.googleapis.com/maps/api/place/nearbysearch/json?location=#{lat},#{lng}&type=gas_station&rankby=distance&key=#{ENV['APIKEY']}")
    topject = resp['results'].first
    if topject.present?
      place_id = topject['place_id']
    else
      return {status: 404}
    end
    resp['results'].first['gas_address_details'] = parse_addr_details(get_addr(place_id)) #this gets the address, city, state, zip of gas station
    #create gasstation here
    gass = GasStation.find_or_create_by(latitude: lat, longitude: lng) do |gas|
      gas_station = resp['results'].first['gas_address_details']
      print "*" * 100
      print gas_station
      gas.street_address = gas_station[:street_address]
      gas.city = gas_station[:city]
      gas.state = gas_station[:state]
      gas.postal_code = gas_station[:postal_code]
      gas.save
    end
    #create location here
    return resp['results'].first
  end

  def find_address_of_call(lat, lng)
    resp = HTTParty.get("https://maps.googleapis.com/maps/api/place/nearbysearch/json?location=#{lat},#{lng}&rankby=distance&key=#{ENV['APIKEY']}")
    result = resp['results'].first
    if result.present?
      place_id = result['place_id']
    else
      return {status: 404}
    end
    lookup_address = parse_addr_details(get_addr(place_id))
    Location.find_or_create_by(latitude: lat, longitude: lng) do |loc|
      loc.street_address = lookup_address[:street_address]
      loc.city = lookup_address[:city]
      loc.state = lookup_address[:state]
      loc.postal_code = lookup_address[:postal_code]
      loc.gas_station_id = GasStation.find_by(latitude:lat, longitude:lng).id
      loc.save
    end

    return lookup_address
  end

  def get_addr(place_id)
    place_id=place_id.gsub(' ', '%20')
    place_detail_url = "https://maps.googleapis.com/maps/api/place/details/json?placeid=#{place_id}&key=#{ENV['APIKEY']}"
    place_detail_url = HTTParty.get(place_detail_url)
    return place_detail_url['result']['address_components']
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


end
