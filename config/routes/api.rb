Openfoodnetwork::Application.routes.draw do
  mount Rswag::Ui::Engine => '/api-docs'
  mount Rswag::Api::Engine => '/api-docs'

  namespace :api do

    # Mount DFC API endpoints
    #
    # Latest implemented version:
    mount DfcProvider::Engine, at: '/dfc/'

    # The DFC prototype is still pointing to the old URL though:
    mount DfcProvider::Engine, at: '/dfc-v1.6/', as: :legacy_dfc_provider_engine
    mount DfcProvider::Engine, at: '/dfc-v1.7/', as: :v1_7_dfc_provider_engine

    namespace :v0 do
      resources :products do
        collection do
          get :bulk_products
          get :overridable
        end
        post :clone

        resources :variants
      end

      resources :variants, :only => [:index]

      resources :orders, only: [:index, :show, :update] do
        member do
          put :capture
          put :ship
        end

        resources :shipments, :only => [:create, :update] do
          member do
            put :ready
            put :ship
            put :add
            put :remove
          end
        end
      end

      resources :enterprises do
        post :update_image, on: :member

        resource :logo, only: [:destroy]
        resource :promo_image, only: [:destroy]
        resource :terms_and_conditions, only: [:destroy]
      end

      resources :shops, only: [:show] do
        collection do
          get :closed_shops
        end
      end

      resources :order_cycles do
        get :products, on: :member
        get :taxons, on: :member
        get :properties, on: :member
      end

      resources :exchanges, only: [:show], to: 'exchange_products#index' do
        get :products, to: 'exchange_products#index'
      end

      resource :status do
        get :job_queue
      end

      resources :customers, only: [:index, :update]

      resources :enterprise_fees, only: [:destroy]

      post '/product_images/:product_id', to: 'product_images#update_product_image'

      resources :states, :only => [:index, :show]

      resources :taxons, :only => [:index]

      resources :taxonomies do
        member do
          get :jstree
        end
        resources :taxons do
          member do
            get :jstree
          end
        end
      end

      get '/reports/:report_type(/:report_subtype)', to: 'reports#show',
          constraints: lambda { |_| OpenFoodNetwork::FeatureToggle.enabled?(:api_reports) }
    end

    namespace :v1 do
      resources :customers

      resources :enterprises do
        resources :customers, only: :index
      end
    end

    match '*path', to: redirect(path: "/api/v0/%{path}"), via: :all, constraints: { path: /(?!v[0-9]).+/ }
  end
end
