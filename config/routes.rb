Rails.application.routes.draw do
  # Rails 8 standard authentication
  resource  :session
  resources :passwords, param: :token
  resource  :registration, only: %i[new create]

  # アプリ本体
  root to: "home#show"
  resource  :home,          only: :show
  resource  :settings,      only: %i[show update]
  resource  :daily_checkin, only: :create

  resources :effort_items, except: %i[show] do
    resource :check, only: %i[create destroy], controller: "effort_checks"
  end

  resources :snacks

  # Health check
  get "up" => "rails/health#show", as: :rails_health_check
end
