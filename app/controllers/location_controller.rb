class LocationController < ApplicationController
  def find_nearest_gs
    if GasStation.where(latitude: params[:lat], longitude: params[:lng]).empty?
      gas_url = nearest_gas(params[:lat], params[:lng])
      a = HTTParty.get(gas_url)
      puts a['results'][0]
    end
    return render :json => {'hello': 'world', url: gas_url}
  end

  private
  def nearest_gas(lat, lng)
    return "https://maps.googleapis.com/maps/api/place/nearbysearch/json?location=#{lat},#{lng}&type=gas_station&rankby=distance&key=#{ENV['APIKEY']}"
  end
end
