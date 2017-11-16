Rails.application.routes.draw do
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
   get 'nearest_gas' => 'location#find_nearest_gs'
   get 'temp_gas' => 'location#temp_gas'
   get 'find_address' => 'location#find_address'
end
