# config/routes.rb
Rails.application.routes.draw do
  root "jobs#index"

  resources :applications, only: [:index, :create, :update, :destroy]
  get "/applications/stats", to: "applications#stats"

  get "jobs/inspect"
  get "jobs/create"
end
