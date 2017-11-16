class GasStation < ApplicationRecord
  has_many :locations, dependent: :destroy
end
