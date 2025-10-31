# Rails.application.routes.draw do
#   get    "/sign_in",  to: "sessions#new",     as: :sign_in
#   post   "/sign_in",  to: "sessions#create"
#   delete "/sign_out", to: "sessions#destroy", as: :sign_out

#   get  "/dashboard", to: "dashboard#show", as: :dashboard
#   root "dashboard#show"

#   resources :applications, only: [ :index, :create, :update, :destroy, :new ]
#   get "/applications/stats", to: "applications#stats"

#   resources :jobs, only: [ :index ]

#   get "jobs/inspect"
# end


Rails.application.routes.draw do
  get    "/sign_in",  to: "sessions#new",     as: :sign_in
  post   "/sign_in",  to: "sessions#create"
  delete "/sign_out", to: "sessions#destroy", as: :sign_out


  root "applications#index"

  get  "/dashboard", to: "dashboard#show", as: :dashboard

  resources :applications, only: [ :index, :create, :update, :destroy, :new ]
  get "/applications/stats", to: "applications#stats"

  resources :jobs, only: [ :index ]
  get "jobs/inspect"
end
