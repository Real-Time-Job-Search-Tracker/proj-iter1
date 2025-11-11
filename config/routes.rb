Rails.application.routes.draw do
  get    "/sign_in",  to: "sessions#new",     as: :sign_in
  post   "/sign_in",  to: "sessions#create"
  delete "/sign_out", to: "sessions#destroy", as: :sign_out

  get "/stats", to: "dashboard#stats"

  root "jobs#index"

  get  "/dashboard", to: "dashboard#show", as: :dashboard
  get "dashboard/stats", to: "dashboard#stats", as: :stats_dashboard, defaults: { format: :json }

  resources :applications, only: [ :index, :create, :update, :destroy, :new, :edit ]
  get "/applications/stats", to: "applications#stats"

  resources :jobs, only: [ :index ]
  get "jobs/inspect"
end
