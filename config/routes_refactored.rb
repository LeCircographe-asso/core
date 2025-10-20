# Routes pour les contrôleurs refactorisés
# À utiliser une fois que les nouveaux contrôleurs sont testés et validés

Rails.application.routes.draw do
  namespace :admin do
    resources :blogs
    resources :dashboard, only: %i[index], path: "dashboard"
    resource :opening_hours, only: %i[show edit update]
    resources :donations, only: %i[create]
    
    # ROUTES REFACTORISÉES - Respecte la structure existante
    resources :users do
      # Actions principales du contrôleur users (inchangées)
      resources :memberships, only: %i[create show update destroy]
      post :restore, on: :member
      post :create_membership, on: :member
      post :create_user_for_person, on: :member
      get :edit_person, on: :member
      get :duplicates, on: :collection
      
      # NOUVELLES ROUTES POUR LES SOUS-CONTRÔLEURS
      # Ces routes utilisent les nouveaux contrôleurs mais gardent la même structure URL
      scope module: :users do
        # Gestion des adhésions via le nouveau contrôleur
        # POST /admin/users/person_1/memberships -> Admin::Users::MembershipsController#create
        post 'person_:person_id/memberships', to: 'memberships#create', as: :person_membership
        
        # Gestion des paiements via le nouveau contrôleur  
        # GET /admin/users/person_1/payments -> Admin::Users::PaymentsController#index
        get 'person_:person_id/payments', to: 'payments#index', as: :person_payments
        post 'person_:person_id/payments', to: 'payments#create'
        
        # Gestion des doublons via le nouveau contrôleur
        # POST /admin/users/duplicates/merge -> Admin::Users::DuplicatesController#merge
        post 'duplicates/merge', to: 'duplicates#merge', on: :collection
        post 'duplicates/cleanup', to: 'duplicates#cleanup', on: :collection
      end
    end
    
    resources :events, only: %i[new create edit destroy index]
    resource :session, only: %i[new create destroy]
    resource :notepad, only: %i[edit update]
    resources :attendance_lists do
      resources :attendances, only: %i[new index create show edit update]
    end
    resources :payments, only: %i[show create new update index destroy]
    resources :attendances, only: %i[index show new create destroy]
    resources :memberships, only: %i[index show new create edit update destroy]
    resources :membership_types, only: %i[index show new create edit update destroy]
    resources :subscription_plans, only: %i[index show new create edit update destroy]
    resources :exports, only: %i[index] do
      get :newsletter_subscribed, on: :collection
      get :all_users, on: :collection
    end
  end

  # Routes publiques (inchangées)
  resources :events, only: %i[show index]
  resources :pages, only: %i[show]
  resource :session, only: %i[new create destroy]
  resources :passwords, only: %i[new create edit update], param: :token
  resource :registration, only: %i[new create]
  resources :event_attendees, only: %i[create destroy]
  resources :blogs, only: %i[show ]
  get "/blog-newsletter", to: "blogs#index"
  resources :users, only: %i[show edit update destroy] do
    post "change_newsletter_status", on: :member
    get "change_newsletter_status", on: :member
  end

  # Route for newsletter signup from footer
  post "/newsletter_signup", to: "users#newsletter_signup", as: "newsletter_signup"

  scope "/checkout" do
    resources :subscriptions, only: %i[new create show]
  end

  root "pages#show", id: "home"
end
