class LocationController < ApplicationController
  def find_nearest_gs
    loc = Location.find_or_create_by(latitude:params[:lat], longitude:params[:lng])
    render :json => loc.parse_locat_gs
  end
end
