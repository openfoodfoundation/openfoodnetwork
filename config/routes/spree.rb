Openfoodnetwork::Application.routes.draw do
  scope module: 'spree' do
    resources :orders, only: [:show, :edit, :update] do
      put :cancel, on: :member
    end
  end
end

# Overriding Devise routes to use our own controller
Spree::Core::Engine.routes.draw do
  devise_for :spree_user,
             :router_name => "spree",
             :class_name => 'Spree::User',
             :controllers => { :sessions => 'spree/user_sessions',
                               :registrations => 'user_registrations',
                               :passwords => 'user_passwords',
                               :confirmations => 'user_confirmations',
                               :omniauth_callbacks => "omniauth_callbacks" },
             :skip => [:unlocks],
             :path_names => { :sign_out => 'logout' },
             :path_prefix => :user

  resources :api_keys, :only => [:create, :destroy]
  resources :users, :only => [:edit, :update]

  devise_scope :spree_user do
    post '/login' => 'user_sessions#create', :as => :create_new_session
    get '/logout' => 'user_sessions#destroy', :as => :logout
    get '/password/recover' => 'user_passwords#new', :as => :recover_password
    post '/password/recover' => 'user_passwords#create', :as => :reset_password
    get '/password/change' => 'user_passwords#edit', :as => :edit_password
    put '/password/change' => 'user_passwords#update', :as => :update_password
  end

  resource :account, :controller => 'users', :only => [:show, :edit, :create, :update] do
    resources :webhook_endpoints, only: [:create, :destroy], controller: '/webhook_endpoints'
    post '/webhook_endpoints/:id/test', to: "/webhook_endpoints#test", as: "webhook_endpoint_test"
  end

  match '/admin/orders/bulk_management' => 'admin/orders#bulk_management', :as => "admin_bulk_order_management", via: :get
  match '/admin/payment_methods/show_provider_preferences' => 'admin/payment_methods#show_provider_preferences', :via => :get
  put 'credit_cards/new_from_token', to: 'credit_cards#new_from_token'

  match '/admin', to: 'admin/overview#index', as: :admin_dashboard, via: :get

  resources :credit_cards, :only => [:update, :destroy]

  namespace :admin do
    get '/search/known_users' => "search#known_users", :as => :search_known_users
    get '/search/customers' => 'search#customers', :as => :search_customers

    resources :users, except: [:show]

    resources :products, except: [:index, :destroy] do
      member do
        get :group_buy_options
        get :seo
      end

      resources :product_properties, except: [:show] do
        collection do
          post :update_positions
        end
      end

      resources :images, except: [:index, :show]

      resources :variants, except: [:show]
    end

    get '/variants/search', :to => "variants#search", :as => :search_variants

    resources :properties, except: [:show]


    post "orders/bulk_credit", to: "orders#bulk_credit"

    resources :orders, except: [:show, :destroy] do
      member do
        put :fire
        get :fire
        get :resend
        get :invoice
        get :print
        put :capture
      end

      collection do
        resources :invoices, only: [:show]
      end

      resources :adjustments, except: [:show]
      resources :invoices, only: [:index]
      resource :invoices, only: [] do
        post :generate
      end

      post "payments/credit_customer", to: "payments#credit_customer"

      resources :payments, only: [:index, :show, :new, :create] do
        member do
          put :fire
          get 'paypal_refund'
          post 'paypal_refund'
        end
      end

      resource :customer, :controller => "orders/customer_details",
                          :only => [:show, :edit, :update]

      resources :return_authorizations, except: [:show] do
        member do
          put :fire
        end
      end
    end

    # Configuration section
    resource :general_settings, :only => [:edit, :update]
    resource :mail_methods, :only => [:edit, :update] do
      post :testmail, :on => :collection
    end

    resources :zones, except: [:show]
    resources :countries, except: [:show] do
      resources :states, except: [:show]
    end
    resources :states, except: [:show]

    resources :taxons, except: :show

    resources :tax_rates, except: [:show]
    resource  :tax_settings, :only => [:edit, :update]
    resources :tax_categories

    resources :shipping_methods, except: [:show]
    resources :shipping_categories, except: [:show]
    resources :payment_methods, except: [:show]
  end
end
