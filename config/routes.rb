Rails.application.routes.draw do
  namespace :admin do
    get "dashboard", to: "dashboard#index"
    resources :dashboard, only: %i[index], path: "dashboard"
    resources :users
    resources :members do
      collection do
        get "membership_register"
        post "membership_recap"
        post "membership_payment"
        post "membership_complete"
        get "reset_membership"
      end
    end
  end

  resource :opening_hours, only: %i[show edit update]

  resources :events
  resources :pages, only: %i[show]
  resource :session, only: %i[new create destroy]
  resources :passwords, only: %i[new create edit update], param: :token
  resource :registration, only: %i[new create]
  resources :event_attendees, only: %i[create destroy]
  resources :users do
    post "change_newsletter_status", on: :member
  end

  scope "/checkout" do
    post "create", to: "checkout#create", as: "checkout_create"
    get "success", to: "checkout#success", as: "checkout_success"
    get "cancel", to: "checkout#cancel", as: "checkout_cancel"
  end

  root "home#index"

  match "*unmatched", to: "application#url_not_found", via: :all
      # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  # root "posts#index"
end
