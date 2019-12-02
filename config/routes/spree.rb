# Overriding Devise routes to use our own controller
Spree::Core::Engine.routes.draw do
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
  end
end

Spree::Core::Engine.routes.prepend do
  match '/admin/reports/orders_and_distributors' => 'admin/reports#orders_and_distributors', :as => "orders_and_distributors_admin_reports",  :via  => [:get, :post]
  match '/admin/reports/order_cycle_management' => 'admin/reports#order_cycle_management', :as => "order_cycle_management_admin_reports",  :via  => [:get, :post]
  match '/admin/reports/packing' => 'admin/reports#packing', :as => "packing_admin_reports",  :via  => [:get, :post]
  match '/admin/reports/group_buys' => 'admin/reports#group_buys', :as => "group_buys_admin_reports",  :via  => [:get, :post]
  match '/admin/reports/bulk_coop' => 'admin/reports#bulk_coop', :as => "bulk_coop_admin_reports",  :via  => [:get, :post]
  match '/admin/reports/payments' => 'admin/reports#payments', :as => "payments_admin_reports",  :via  => [:get, :post]
  match '/admin/reports/orders_and_fulfillment' => 'admin/reports#orders_and_fulfillment', :as => "orders_and_fulfillment_admin_reports",  :via  => [:get, :post]
  match '/admin/reports/users_and_enterprises' => 'admin/reports#users_and_enterprises', :as => "users_and_enterprises_admin_reports",  :via => [:get, :post]
  match '/admin/reports/sales_tax' => 'admin/reports#sales_tax', :as => "sales_tax_admin_reports",  :via  => [:get, :post]
  match '/admin/orders/bulk_management' => 'admin/orders#bulk_management', :as => "admin_bulk_order_management"
  match '/admin/reports/products_and_inventory' => 'admin/reports#products_and_inventory', :as => "products_and_inventory_admin_reports",  :via  => [:get, :post]
  match '/admin/reports/customers' => 'admin/reports#customers', :as => "customers_admin_reports",  :via  => [:get, :post]
  match '/admin/reports/xero_invoices' => 'admin/reports#xero_invoices', :as => "xero_invoices_admin_reports",  :via  => [:get, :post]
  match '/admin', :to => 'admin/overview#index', :as => :admin
  match '/admin/payment_methods/show_provider_preferences' => 'admin/payment_methods#show_provider_preferences', :via => :get
  put 'credit_cards/new_from_token', to: 'credit_cards#new_from_token'

  resources :credit_cards

  namespace :admin do
    get '/search/known_users' => "search#known_users", :as => :search_known_users
    get '/search/customers' => 'search#customers', :as => :search_customers
    get '/search/customer_addresses' => 'search#customer_addresses', :as => :search_customer_addresses

    resources :products do
      get :group_buy_options, on: :member
      get :seo, on: :member

      post :bulk_update, :on => :collection, :as => :bulk_update
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

      resources :adjustments
    end

    resources :users do
      member do
        put :generate_api_key
        put :clear_api_key
      end
    end

    # Configuration section
    resource :general_settings
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

    resources :taxons, :only => [] do
      collection do
        get :search
      end
    end

    resources :tax_rates
    resource  :tax_settings
    resources :tax_categories
  end

  resources :orders do
    get :clear, :on => :collection
    get :order_cycle_expired, :on => :collection
    put :cancel, on: :member
  end

  resources :products

  # Used by spree_paypal_express
  get '/checkout/:state', :to => 'checkout#edit', :as => :checkout_state

  get '/unauthorized', :to => 'home#unauthorized', :as => :unauthorized
  get '/content/cvv', :to => 'content#cvv', :as => :cvv
  get '/content/*path', :to => 'content#show', :as => :content
end
