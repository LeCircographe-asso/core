Rails.application.routes.draw do
  namespace :admin do
    resources :blogs
    resources :dashboard, only: %i[index], path: "dashboard"
    resource :opening_hours, only: %i[show edit update]
    resources :donations ,only: %i[create]
    resources :users do
      resources :orders, only: %i[create show index update]do
        resources :product_orders, only: [:destroy]
        end
      resources :user_membership, only: %i[create show update destroy]
    end
    resources :events, only: %i[new create edit destroy index]
    resource :session, only: %i[new create destroy]
    resource :notepad, only: %i[show edit update]
    resources :attendance_lists do
      resources :attendances, only: %i[new index create show edit update]
    end
    resources :product_orders, only: %i[create update]
    resources :products, only: %i[index]
    resources :payments, only: %i[show create new update index]
    resources :exports, only: %i[index] do
      get :newsletter_subscribed, on: :collection
    end
  end

  resources :events, only: %i[show index]
  resources :pages, only: %i[show]
  resource :session, only: %i[new create destroy]
  resources :passwords, only: %i[new create edit update], param: :token
  resource :registration, only: %i[new create]
  resources :event_attendees, only: %i[create destroy]
  resources :blogs, only: %i[show ]
  get "/blog-newsletter", to: "blogs#index"
  resources :users do
    post "change_newsletter_status", on: :member
    get "change_newsletter_status", on: :member
  end

  scope "/checkout" do
    post "create", to: "checkout#create", as: "checkout_create"
    get "success", to: "checkout#success", as: "checkout_success"
    get "cancel", to: "checkout#cancel", as: "checkout_cancel"
  end

  root "home#index"

  # match "*unmatched", to: "application#url_not_found", via: :all
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  # root "posts#index"

  # Route pour le formulaire de contact
  post "/submit_contact", to: "contacts#create"

  if Rails.env.development?
    mount LetterOpenerWeb::Engine, at: "/letter_opener"
  end
end
