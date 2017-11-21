Rails.application.routes.draw do
   get 'nearest_gas' => 'location#find_nearest_gs'
end
