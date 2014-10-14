Openfoodnetwork::Application.routes.draw do
  root :to => 'home#index'

  get "/#/login", to: "home#index", as: :spree_login

  get "/map", to: "map#index", as: :map

  get "/register", to: "registration#index", as: :registration
  get "/register/store", to: "registration#store", as: :store_registration
  get "/register/auth", to: "registration#authenticate", as: :registration_auth

  resource :shop, controller: "shop" do
    get :products
    post :order_cycle
    get :order_cycle
  end

  resources :groups
  resources :producers

  get '/checkout', :to => 'checkout#edit' , :as => :checkout
  put '/checkout', :to => 'checkout#update' , :as => :update_checkout
  get '/checkout/paypal_payment/:order_id', to: 'checkout#paypal_payment', as: :paypal_payment

  resources :enterprises do
    collection do
      get :suppliers
      get :distributors
      post :search
    end

    member do
      get :shop_front # new world
      get :shop # old world
    end
  end

  devise_for :enterprise

  namespace :admin do
    resources :order_cycles do
      post :bulk_update, on: :collection, as: :bulk_update
      get :clone, on: :member
    end

    resources :enterprises do
      collection do
        get :for_order_cycle
        post :bulk_update, as: :bulk_update
      end

      resources :producer_properties do
        post :update_positions, on: :collection
      end
    end

    resources :enterprise_relationships
    resources :enterprise_roles

    resources :enterprise_fees do
      post :bulk_update, :on => :collection, :as => :bulk_update
    end

    resources :enterprise_groups do
      get :move_up
      get :move_down
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
  end

  get "about_us", :controller => 'home', :action => "about_us"

  namespace :open_food_network do
    resources :cart do
      post :add_variant
    end
  end

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
  match '/admin/reports/group_buys' => 'admin/reports#group_buys', :as => "group_buys_admin_reports",  :via  => [:get, :post]
  match '/admin/reports/bulk_coop' => 'admin/reports#bulk_coop', :as => "bulk_coop_admin_reports",  :via  => [:get, :post]
  match '/admin/reports/payments' => 'admin/reports#payments', :as => "payments_admin_reports",  :via  => [:get, :post]
  match '/admin/reports/orders_and_fulfillment' => 'admin/reports#orders_and_fulfillment', :as => "orders_and_fulfillment_admin_reports",  :via  => [:get, :post]
  match '/admin/products/bulk_edit' => 'admin/products#bulk_edit', :as => "bulk_edit_admin_products"
  match '/admin/orders/bulk_management' => 'admin/orders#bulk_management', :as => "admin_bulk_order_management"
  match '/admin/reports/products_and_inventory' => 'admin/reports#products_and_inventory', :as => "products_and_inventory_admin_reports",  :via  => [:get, :post]
  match '/admin/reports/customers' => 'admin/reports#customers', :as => "customers_admin_reports",  :via  => [:get, :post]
  match '/admin', :to => 'admin/overview#index', :as => :admin
  match '/admin/payment_methods/show_provider_preferences' => 'admin/payment_methods#show_provider_preferences', :via => :get


  namespace :api, :defaults => { :format => 'json' } do
    resources :users do
      get :authorise_api, on: :collection
    end

    resources :products do
      get :managed, on: :collection
      get :bulk_products, on: :collection
      delete :soft_delete

      resources :variants do
        delete :soft_delete
      end
    end

    resources :orders do
      get :managed, on: :collection
    end
  end

  namespace :admin do
    resources :products do
      get :product_distributions, on: :member

      post :bulk_update, :on => :collection, :as => :bulk_update
    end
  end

  resources :orders do
    get :select_distributor, :on => :member
    get :deselect_distributor, :on => :collection
    get :clear, :on => :collection
    get :order_cycle_expired, :on => :collection
  end

end
