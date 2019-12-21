# Overriding Devise routes to use our own controller
Spree::Core::Engine.routes.draw do
  root to: 'home#index'

  devise_for :spree_user,
             :class_name => 'Spree::User',
             :controllers => { :sessions => 'spree/user_sessions',
                               :registrations => 'user_registrations',
                               :passwords => 'user_passwords',
                               :confirmations => 'user_confirmations'},
             :skip => [:unlocks, :omniauth_callbacks],
             :path_names => { :sign_out => 'logout' },
             :path_prefix => :user

  resources :users, :only => [:edit, :update]

  devise_scope :spree_user do
    get '/login' => 'user_sessions#new', :as => :login
    post '/login' => 'user_sessions#create', :as => :create_new_session
    get '/logout' => 'user_sessions#destroy', :as => :logout
    get '/signup' => 'user_registrations#new', :as => :signup
    post '/signup' => 'user_registrations#create', :as => :registration
    get '/password/recover' => 'user_passwords#new', :as => :recover_password
    post '/password/recover' => 'user_passwords#create', :as => :reset_password
    get '/password/change' => 'user_passwords#edit', :as => :edit_password
    put '/password/change' => 'user_passwords#update', :as => :update_password
  end

  resource :account, :controller => 'users'

  namespace :admin do
    resources :users

    namespace :reports do
      match 'orders_and_distributors', to: 'admin/reports#orders_and_distributors', via: [:get, :post]
      match 'order_cycle_management', to: 'admin/reports#order_cycle_management', via: [:get, :post]
      match 'packing', to: 'admin/reports#packing',via: [:get, :post]
      match 'group_buys', to: 'admin/reports#group_buys', via: [:get, :post]
      match 'bulk_coop', to: 'admin/reports#bulk_coop', via: [:get, :post]
      match 'payments', to: 'admin/reports#payments', via: [:get, :post]
      match 'orders_and_fulfillment', to: 'admin/reports#orders_and_fulfillment', via: [:get, :post]
      match 'users_and_enterprises', to: 'admin/reports#users_and_enterprises', via: [:get, :post]
      match 'sales_tax', to: 'admin/reports#sales_tax', via: [:get, :post]
      match 'products_and_inventory', to: 'admin/reports#products_and_inventory', via: [:get, :post]
      match 'customers', to: 'admin/reports#customers', via: [:get, :post]
      match 'xero_invoices', to: 'admin/reports#xero_invoices', via: [:get, :post]
    end

    get '/search/known_users' => "search#known_users", :as => :search_known_users
    get '/search/customers' => 'search#customers', :as => :search_customers
    get '/search/customer_addresses' => 'search#customer_addresses', :as => :search_customer_addresses

    resources :products do
      get :group_buy_options, on: :member
      get :seo, on: :member

      post :bulk_update, on: :collection, as: :bulk_update
    end

    resources :orders do
      get :invoice, on: :member
      get :print, on: :member
      get :print_ticket, on: :member
      get :managed, on: :collection

      collection do
        resources :invoices, only: [:create, :show] do
          get :poll
        end
      end
    end

    resources :users do
      member do
        put :generate_api_key
        put :clear_api_key
      end
    end

    # Configuration section
    resource :general_settings do
      collection do
        post :dismiss_alert
      end
    end

    resource :mail_method, :only => [:edit, :update] do
      post :testmail, :on => :collection
    end

    resource :image_settings

    resources :zones
    resources :countries do
      resources :states
    end
    resources :states

    resources :taxonomies do
      collection do
        post :update_positions
      end
      member do
        get :get_children
      end
      resources :taxons
    end

    resources :taxons, only: [] do
      collection do
        get :search
      end
    end

    resources :tax_rates
    resource  :tax_settings
    resources :tax_categories
  end

  #match '/admin', :to => 'admin/overview#index', :as => :admin, via: :get
  match '/admin/orders/bulk_management', to: 'admin/orders#bulk_management', via: :get
  match '/admin/payment_methods/show_provider_preferences', to: 'admin/payment_methods#show_provider_preferences', via: :get
  put 'credit_cards/new_from_token', to: 'credit_cards#new_from_token'

  resources :credit_cards

  resources :orders do
    get :clear, :on => :collection
    get :order_cycle_expired, :on => :collection
    put :cancel, on: :member
  end

  resources :products

  # Used by spree_paypal_express
  #get '/checkout/:state', :to => 'checkout#edit', :as => :checkout_state

  get '/unauthorized', :to => 'home#unauthorized', :as => :unauthorized
  get '/content/cvv', :to => 'content#cvv', :as => :cvv
  get '/content/*path', :to => 'content#show', :as => :content
end
