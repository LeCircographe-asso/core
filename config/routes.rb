Rails.application.routes.draw do
  namespace :admin do
    root to: 'dashboard#index'
    resources :blogs
    resources :dashboard, only: %i[index], path: 'dashboard'
    resource :opening_hours, only: %i[show edit update]
    resources :donations, only: %i[create]
    resources :users do
      post :restore, on: :member
      # Actions pour gérer Person
      get :edit_person, on: :member
      # Actions pour gérer les doublons
      get :duplicates, on: :collection

      resources :payments, module: :users, only: %i[index new create show update destroy] do
        post :process_payment, on: :member
      end
    end
    resources :events, only: %i[new create edit update destroy index]
    resource :session, only: %i[new create destroy]
    resource :notepad, only: %i[edit update]
    resources :attendance_lists do
      resources :attendances, only: %i[new index create show edit update]
    end
    resources :payments, only: %i[show create new edit update index destroy] do
      post :restore, on: :member
    end
    resources :health_reports, only: %i[index]
    resources :attendances, only: %i[index show new create destroy]
    resources :memberships, only: %i[index show new create edit update destroy]
    resources :membership_types, only: %i[index show new create edit update destroy]
    resources :subscription_plans, only: %i[index show new create edit update destroy]
    resources :subscriptions, only: [] do
      post :upgrade, on: :collection
    end
    resources :member_numbers, only: [] do
      post :suggest, on: :collection
      patch :change, on: :member
    end
    resources :duplicates, only: %i[index] do
      post :merge, on: :collection
    end
    resources :exports, only: %i[index] do
      get :newsletter_subscribed, on: :collection
      get :all_users, on: :collection
    end
  end

  resources :events, only: %i[show index] do
    get :upcoming, on: :collection
    get :past, on: :collection
  end
  resources :pages, only: %i[show]
  resource :session, only: %i[new create destroy]
  resources :passwords, only: %i[new create edit update], param: :token
  resource :registration, only: %i[new create]
  resources :event_interests, only: %i[create destroy]
  resources :blogs, only: %i[show] do
    get :latest, on: :collection
  end
  resources :partners, only: %i[index]
  get '/blog-newsletter', to: 'blogs#index'
  resources :users, only: %i[show edit update destroy] do
    post 'change_newsletter_status', on: :member
    get 'change_newsletter_status', on: :member
  end

  # Routes pour revendication de compte
  resources :account_claims, only: %i[new create] do
    get :confirm, on: :collection
  end

  # Route for newsletter signup from footer
  post '/newsletter_signup', to: 'users#newsletter_signup', as: 'newsletter_signup'

  # Route for newsletter unsubscribe by token (from emails)
  get '/newsletter/unsubscribe/:token', to: 'users#unsubscribe_by_token', as: 'newsletter_unsubscribe'

  scope '/checkout' do
    post 'create', to: 'checkout#create', as: 'checkout_create'
    get 'success', to: 'checkout#success', as: 'checkout_success'
    get 'cancel', to: 'checkout#cancel', as: 'checkout_cancel'
  end

  root 'home#index'
  get 'fonts', to: 'home#font_examples', as: 'font_examples'
  get '/faq', to: 'faqs#index', as: :faq

  # match "*unmatched", to: "application#url_not_found", via: :all
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get 'up' => 'rails/health#show', as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  get 'manifest' => 'rails/pwa#manifest', as: :pwa_manifest
  get 'service-worker' => 'rails/pwa#service_worker', as: :pwa_service_worker

  # Defines the root path route ("/")
  # root "posts#index"

  # Route pour le formulaire de contact
  post '/submit_contact', to: 'contacts#create'

  mount LetterOpenerWeb::Engine, at: '/letter_opener' if Rails.env.development?

  resource :password, only: %i[new create edit update] do
    get :request_reset, on: :collection
  end

  resource :settings, only: %i[show update], controller: 'settings'
end
