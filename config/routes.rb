# config/routes.rb
Rails.application.routes.draw do
  root "jobs#index"

  resources :applications, only: [:index, :create, :update, :destroy]
  get "/applications/stats", to: "applications#stats"

  # create should be POST (keep if you need it)
  resources :jobs, only: [:create]
end
