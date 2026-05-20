Rails.application.routes.draw do
  # Rails 8 standard authentication
  resource  :session
  resources :passwords, param: :token

  # Health check
  get "up" => "rails/health#show", as: :rails_health_check

  root to: "home#index"
  get "home/index"
end
