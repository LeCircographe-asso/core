# frozen_string_literal: true

# route_name => [page_id, url_slug] — source de vérité unique pour les pages publiques
PUBLIC_PAGES = {
  about:                     %w[about about],
  association:               %w[association association],
  adhesion:                  %w[become_member adhesion],
  actualites:                %w[news actualites],
  contact:                   %w[contact_us contact],
  faq:                       %w[faq faq],
  galerie:                   %w[gallery galerie],
  mentions_legales:          %w[terms mentions-legales],
  confidentialite:           %w[privacy_policy confidentialite],
  newsletter_desinscription: %w[newsletter_unsubscribe_success newsletter/desinscription-confirmee]
}.freeze

PAGE_ID_TO_ROUTE = PUBLIC_PAGES.each_with_object({}) { |(name, (pid, _)), h| h[pid] = name }.freeze

Rails.application.routes.draw do
  namespace :admin do
    root to: "dashboard#index"
    resources :blogs
    resources :dashboard, only: %i[index], path: "dashboard"
    resource :opening_hours, only: %i[show edit update]
    # Legacy: "Faire un don" used GET /admin/donations?person_id=… before +new+ existed.
    get "donations", to: redirect { |_path_params, request|
      query = request.query_string
      query.present? ? "/admin/donations/new?#{query}" : "/admin/donations/new"
    }
    resources :donations, only: %i[new create]
    resources :members, controller: "members" do
      post :restore, on: :member
      post :create_web_account, on: :member
      get :edit_person, on: :member
      resources :payments, module: :members, only: %i[index new create show update destroy] do
        post :process_payment, on: :member
      end
    end
    resources :events, only: %i[new create edit update destroy index]
    resource :session, only: %i[new create destroy]
    resource :notepad, only: %i[edit update]
    resource :faq, only: %i[edit update], controller: "faq_config"
    resources :faqs, only: %i[index new create edit update destroy] do
      collection { patch :reorder }
    end
    resources :attendance_lists do
      resources :attendances, only: %i[new index create show destroy]
    end
    resources :payments, only: %i[show create new edit update index destroy] do
      post :restore, on: :member
    end
    resources :health_reports, only: %i[index]
    resources :attendances, only: %i[index show new create destroy]
    resources :memberships, only: %i[index show new create edit update destroy]
    resources :membership_types, only: %i[index show new create edit update destroy]
    resources :contribution_formulas, only: %i[index show new create edit update destroy]
    resources :contributions, only: [] do
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

  # Pages publiques — générées depuis PUBLIC_PAGES (une seule source de vérité)
  PUBLIC_PAGES.each do |route_name, (page_id, slug)|
    get "/#{slug}", to: "pages#show", defaults: { id: page_id }, as: route_name
  end

  # page_path('become_member') => '/adhesion'
  # page_path('news', anchor: 'evenements') => '/actualites#evenements'
  direct(:page) do |id, options|
    route_name = PAGE_ID_TO_ROUTE[id.to_s] || :root
    send(:"#{route_name}_path", **options)
  end

  # Redirects permanents /pages/:id → URL propre (bookmarks, SEO, liens emails)
  get "/pages/:id", to: redirect(status: 301) { |params, _|
    route_name = PAGE_ID_TO_ROUTE[params[:id]]
    if route_name
      "/#{PUBLIC_PAGES[route_name][1]}"
    else
      { "blog_newsletter"      => "/",
        "circus_details"       => "/association#le-cirque",
        "graphic_arts_details" => "/association#les-arts-graphiques" }.fetch(params[:id], "/")
    end
  }

  resource :session, only: %i[new create destroy]
  resources :passwords, only: %i[new create edit update], param: :token
  resource :registration, only: %i[new create]
  resources :event_interests, only: %i[create destroy]
  resources :blogs, only: %i[show] do
    get :latest, on: :collection
  end
  resources :partners, only: %i[index]
  get "/blog-newsletter", to: "blogs#index"
  resources :users, only: %i[show edit update destroy] do
    post "change_newsletter_status", on: :member
    get "change_newsletter_status", on: :member
  end

  # Routes pour revendication de compte
  resources :account_claims, only: %i[new create] do
    get :confirm, on: :collection
  end

  # Route for newsletter signup from footer
  post "/newsletter_signup", to: "users#newsletter_signup", as: "newsletter_signup"

  # Route for newsletter unsubscribe by token (from emails)
  get "/newsletter/unsubscribe/:token", to: "users#unsubscribe_by_token", as: "newsletter_unsubscribe"

  scope "/checkout" do
    post "create", to: "checkout#create", as: "checkout_create"
    get "success", to: "checkout#success", as: "checkout_success"
    get "cancel", to: "checkout#cancel", as: "checkout_cancel"
  end

  root "home#index"
  get "fonts", to: "home#font_examples", as: "font_examples"
  get "/white-page", to: "pages#show", defaults: { id: "white_page" }, as: :white_page

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

  mount LetterOpenerWeb::Engine, at: "/letter_opener" if Rails.env.development?

  resource :password, only: %i[new create edit update] do
    get :request_reset, on: :collection
  end

  resource :settings, only: %i[show update], controller: "settings"
end
