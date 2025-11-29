Rails.application.routes.draw do
  # AUTH
  get    "/sign_in",  to: "sessions#new",     as: :sign_in
  post   "/sign_in",  to: "sessions#create"
  delete "/sign_out", to: "sessions#destroy", as: :sign_out

  get  "/sign_up", to: "users#new",    as: :sign_up
  post "/sign_up", to: "users#create"

  # Root should show the dashboard in demo mode for guests
  root "dashboard#show"

  # DASHBOARD
  get "/dashboard",       to: "dashboard#show",  as: :dashboard
  get "/dashboard/stats", to: "dashboard#stats",
                          as: :stats_dashboard,
                          defaults: { format: :json }

  # JOBS
  resources :jobs, only: [ :index ]
  get "/jobs/preview", to: "jobs#preview", defaults: { format: :json }
  get "/jobs/inspect", to: "jobs#inspect", as: :inspect_job

  # SANKEY API
  get "/sankey", to: "sankey#index", as: :sankey_api

  # APPLICATIONS
  resources :applications, only: [ :index, :create, :update, :destroy, :new, :edit ]
  get "/applications/stats", to: "applications#stats", defaults: { format: :json }
end
