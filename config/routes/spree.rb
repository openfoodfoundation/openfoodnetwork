Openfoodnetwork::Application.routes.draw do
  scope module: 'spree' do
    resources :orders do
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

  resource :account, :controller => 'users'

  match '/admin/orders/bulk_management' => 'admin/orders#bulk_management', :as => "admin_bulk_order_management", via: :get
  match '/admin/payment_methods/show_provider_preferences' => 'admin/payment_methods#show_provider_preferences', :via => :get
  put 'credit_cards/new_from_token', to: 'credit_cards#new_from_token'

  match '/admin', to: 'admin/overview#index', as: :admin_dashboard, via: :get

  resources :credit_cards

  namespace :admin do
    get '/search/known_users' => "search#known_users", :as => :search_known_users
    get '/search/customers' => 'search#customers', :as => :search_customers

    resources :users

    resources :products do
      post :bulk_update, :on => :collection, :as => :bulk_update

      member do
        get :clone
        get :group_buy_options
        get :seo
      end

      resources :product_properties do
        collection do
          post :update_positions
        end
      end

      resources :images do
        collection do
          post :update_positions
        end
      end

      resources :variants do
        collection do
          post :update_positions
        end
      end
    end

    get '/variants/search', :to => "variants#search", :as => :search_variants

    resources :properties

    resources :orders do
      member do
        put :fire
        get :fire
        post :resend
        get :invoice
        get :print
      end

      collection do
        get :managed

        resources :invoices, only: [:create, :show] do
          get :poll
        end
      end

      resources :adjustments

      resources :payments do
        member do
          put :fire
          get 'paypal_refund'
          post 'paypal_refund'
        end
      end

      resource :customer, :controller => "orders/customer_details"

      resources :return_authorizations do
        member do
          put :fire
        end
      end
    end

    # Configuration section
    resource :general_settings
    resource :mail_methods, :only => [:edit, :update] do
      post :testmail, :on => :collection
    end

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

    resources :tax_rates
    resource  :tax_settings
    resources :tax_categories

    resources :shipping_methods
    resources :shipping_categories
    resources :payment_methods
  end

  resources :products
end
