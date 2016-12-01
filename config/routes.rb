Openfoodnetwork::Application.routes.draw do
  root :to => 'home#index'

  # Redirects from old URLs avoid server errors and helps search engines
  get "/enterprises", to: redirect("/")
  get "/products", to: redirect("/")
  get "/products/:id", to: redirect("/")
  get "/t/products/:id", to: redirect("/")
  get "/about_us", to: redirect(ContentConfig.footer_about_url)

  get "/#/login", to: "home#index", as: :spree_login
  get "/login", to: redirect("/#/login")

  get "/discourse/login", to: "discourse_sso#login"
  get "/discourse/sso", to: "discourse_sso#sso"

  get "/map", to: "map#index", as: :map
  get "/sell", to: "home#sell", as: :sell

  get "/register", to: "registration#index", as: :registration
  get "/register/auth", to: "registration#authenticate", as: :registration_auth

  # Redirects to global website
  get "/connect", to: redirect("https://openfoodnetwork.org/#{ENV['DEFAULT_COUNTRY_CODE'].andand.downcase}/connect/")
  get "/learn", to: redirect("https://openfoodnetwork.org/#{ENV['DEFAULT_COUNTRY_CODE'].andand.downcase}/learn/")

  resource :shop, controller: "shop" do
    get :products
    post :order_cycle
    get :order_cycle
    get :changeable_orders_alert
  end

  resources :producers, only: [:index] do
    collection do
      get :signup
    end
  end

  resources :shops, only: [:index] do
    collection do
      get :signup
    end
  end

  resources :line_items, only: [:destroy] do
    get :bought, on: :collection
  end

  resources :groups, only: [:index, :show] do
    collection do
      get :signup
    end
  end

  namespace :stripe do
    resources :callbacks, only: [:index]
    resources :webhooks, only: [:create]
  end

  namespace :admin do
    resources :bulk_line_items
  end

  get '/checkout', :to => 'checkout#edit' , :as => :checkout
  put '/checkout', :to => 'checkout#update' , :as => :update_checkout
  get '/checkout/paypal_payment/:order_id', to: 'checkout#paypal_payment', as: :paypal_payment

  get 'embedded_shopfront/shopfront_session', to: 'application#shopfront_session'
  post 'embedded_shopfront/enable', to: 'application#enable_embedded_styles'
  post 'embedded_shopfront/disable', to: 'application#disable_embedded_styles'

  resources :enterprises do
    collection do
      post :search
      get :check_permalink
    end

    member do
      get :shop
      get :relatives
    end
  end
  get '/:id/shop', to: 'enterprises#shop', as: 'enterprise_shop'
  get "/enterprises/:permalink", to: redirect("/") # Legacy enterprise URL

  devise_for :enterprise, controllers: { confirmations: 'enterprise_confirmations' }

  namespace :admin do
    resources :order_cycles do
      post :bulk_update, on: :collection, as: :bulk_update

      member do
        get :clone
        post :notify_producers
      end
    end

    resources :enterprises do
      collection do
        get :for_order_cycle
        get :visible
        post :bulk_update, as: :bulk_update
      end

      member do
        get :welcome
        put :register
      end

      resources :producer_properties do
        post :update_positions, on: :collection
      end

      resources :tag_rules, only: [:destroy]
    end

    resources :enterprise_relationships
    resources :enterprise_roles

    resources :enterprise_fees do
      collection do
        get :for_order_cycle
        post :bulk_update, :as => :bulk_update
      end
    end

    resources :enterprise_groups do
      get :move_up
      get :move_down
    end

    get '/inventory', to: 'variant_overrides#index'

    get '/product_import', to: 'product_import#index'
    post '/product_import', to: 'product_import#import'
    post '/product_import/save', to: 'product_import#save', as: 'product_import_save'

    resources :variant_overrides do
      post :bulk_update, on: :collection
      post :bulk_reset, on: :collection
    end

    resources :inventory_items, only: [:create, :update]

    resources :customers, only: [:index, :create, :update, :destroy]

    resources :tag_rules, only: [], format: :json do
      get :map_by_tag, on: :collection
    end

    resource :content

    resource :accounts_and_billing_settings, only: [:edit, :update] do
      collection do
        get :show_methods
        get :start_job
      end
    end

    resource :business_model_configuration, only: [:edit, :update], controller: 'business_model_configuration'

    resource :cache_settings

    resource :account, only: [:show], controller: 'account'

    resources :column_preferences, only: [], format: :json do
      put :bulk_update, on: :collection
    end

    resource :invoice_settings, only: [:edit, :update]

    resource :stripe_connect_settings, only: [:edit, :update]

    resources :stripe_accounts, only: [:destroy] do
      get :connect, on: :collection
      get :status, on: :collection
    end

    resources :schedules, only: [:index, :create, :update, :destroy], format: :json

    resources :standing_orders, only: [:index, :new, :create, :edit, :update]

    resources :standing_line_items, only: [], format: :json do
      post :build, on: :collection
    end
  end

  namespace :api do
    resources :enterprises do
      post :update_image, on: :member
      get :managed, on: :collection
      get :accessible, on: :collection
    end
    resources :order_cycles do
      get :managed, on: :collection
      get :accessible, on: :collection
    end

    resource :status do
      get :job_queue
    end
  end

  namespace :open_food_network do
    resources :cart do
      post :add_variant
    end
  end

  get 'sitemap.xml', to: 'sitemap#index', defaults: { format: 'xml' }

  # Mount Spree's routes
  mount Spree::Core::Engine, :at => '/'

end


# Overriding Devise routes to use our own controller
Spree::Core::Engine.routes.draw do
  devise_for :spree_user,
             :class_name => 'Spree::User',
             :controllers => { :sessions => 'spree/user_sessions',
                               :registrations => 'user_registrations',
                               :passwords => 'user_passwords' },
             :skip => [:unlocks, :omniauth_callbacks],
             :path_names => { :sign_out => 'logout' },
             :path_prefix => :user
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
  match '/admin/products/bulk_edit' => 'admin/products#bulk_edit', :as => "bulk_edit_admin_products"
  match '/admin/orders/bulk_management' => 'admin/orders#bulk_management', :as => "admin_bulk_order_management"
  match '/admin/reports/products_and_inventory' => 'admin/reports#products_and_inventory', :as => "products_and_inventory_admin_reports",  :via  => [:get, :post]
  match '/admin/reports/customers' => 'admin/reports#customers', :as => "customers_admin_reports",  :via  => [:get, :post]
  match '/admin/reports/xero_invoices' => 'admin/reports#xero_invoices', :as => "xero_invoices_admin_reports",  :via  => [:get, :post]
  match '/admin', :to => 'admin/overview#index', :as => :admin
  match '/admin/payment_methods/show_provider_preferences' => 'admin/payment_methods#show_provider_preferences', :via => :get
  put 'credit_cards/new_from_token', to: 'credit_cards#new_from_token'

  resources :credit_cards


  namespace :api, :defaults => { :format => 'json' } do
    resources :users do
      get :authorise_api, on: :collection
    end

    resources :products do
      collection do
        get :managed
        get :bulk_products
        get :overridable
      end
      delete :soft_delete
      post :clone

      resources :variants do
        delete :soft_delete
      end
    end

    resources :orders do
      get :managed, on: :collection
    end

  end

  namespace :admin do
    get '/search/known_users' => "search#known_users", :as => :search_known_users
    get '/search/customers' => 'search#customers', :as => :search_customers

    resources :products do
      get :product_distributions, on: :member
      get :group_buy_options, on: :member
      get :seo, on: :member

      post :bulk_update, :on => :collection, :as => :bulk_update
    end

    resources :orders do
      get :invoice, on: :member
      get :print, on: :member
      get :print_ticket, on: :member
      get :managed, on: :collection
    end
  end

  resources :orders do
    get :clear, :on => :collection
    get :order_cycle_expired, :on => :collection
    put :cancel, on: :member
  end

end
