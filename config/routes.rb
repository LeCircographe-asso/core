Rails.application.routes.draw do
  get "le_cirque", to: "pages#le_cirque", as: :le_cirque
  get "le_graff", to: "pages#le_graff", as: :le_graff
  get "le_lieu", to: "pages#le_lieu", as: :le_lieu
  get "about", to: "pages#about", as: :about
  
  
  namespace :admin do
    get 'dashboard', to: 'dashboard#index'
    resources :users
  end

  resource :session, only: %i[new create destroy]
  resources :passwords, param: :token
  resource :registration, only: %i[new create]
  resources :users
  
  root "home#index"



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
