class GasStation < ApplicationRecord
  has_one :location, dependent: :destroy
  validates :longitude, presence: true
  validates :latitude, presence: true, uniqueness: {scope: [:longitude]}
  validates :state, presence: true
  validates :city, presence: true
  validates :street_address, presence: true
end
