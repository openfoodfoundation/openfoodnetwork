require 'sidekiq/web'
require 'sidekiq-scheduler/web'

Openfoodnetwork::Application.routes.draw do
  namespace :admin do

    authenticated :spree_user, -> user { user.admin? } do
      mount Flipper::UI.app(Flipper) => '/feature-toggle'
      mount Sidekiq::Web, at: "/sidekiq"
    end

    resources :bulk_line_items

    resources :order_cycles do
      post :bulk_update, on: :collection, as: :bulk_update
      get :incoming
      get :outgoing
      get :checkout_options

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
        patch :register
      end

      resources :producer_properties do
        post :update_positions, on: :collection
      end

      resources :tag_rules, only: [:destroy]

      constraints FeatureToggleConstraint.new(:vouchers) do
        resources :vouchers, only: [:new, :create]
      end
    end

    resources :enterprise_relationships
    resources :enterprise_roles

    resources :enterprise_fees, except: :destroy do
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
    post '/product_import/validate_data', to: 'product_import#validate_data', as: 'product_import_process_async'
    post '/product_import/save_data', to: 'product_import#save_data', as: 'product_import_save_async'
    post '/product_import/reset_absent', to: 'product_import#reset_absent_products', as: 'product_import_reset_async'

    constraints FeatureToggleConstraint.new(:admin_style_v3) do
      get '/products_v3', to: 'products_v3#index'
    end

    resources :variant_overrides do
      post :bulk_update, on: :collection
      post :bulk_reset, on: :collection
    end

    resources :inventory_items, only: [:create, :update]

    resources :customers, only: [:index, :create, :update, :destroy, :show]

    resources :tag_rules, only: [], format: :json do
      get :map_by_tag, on: :collection
    end

    resource :contents

    resources :column_preferences, only: [], format: :json do
      put :bulk_update, on: :collection
    end

    resource :invoice_settings, only: [:edit, :update]

    resource :stripe_connect_settings, only: [:edit, :update]

    resource :terms_of_service_files

    resource :matomo_settings, only: [:edit, :update]

    resources :stripe_accounts, only: [:destroy] do
      get :connect, on: :collection
      get :status, on: :collection
    end

    resources :schedules, only: [:index, :create, :update, :destroy], format: :json

    resources :subscriptions, only: [:index, :new, :create, :edit, :update] do
      put :cancel, on: :member
      put :pause, on: :member
      put :unpause, on: :member
    end

    resources :oidc_settings, only: :index

    resources :subscription_line_items, only: [], format: :json do
      post :build, on: :collection
    end

    resources :proxy_orders, only: [:edit] do
      put :cancel, on: :member, format: :json
      put :resume, on: :member, format: :json
    end

    get '/reports', to: 'reports#index', as: :reports
    match '/reports/:report_type(/:report_subtype)', to: 'reports#show', via: [:get, :post], as: :report
  end
end
