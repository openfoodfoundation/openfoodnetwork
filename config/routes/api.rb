Openfoodnetwork::Application.routes.draw do
  unless Rails.env.production?
    # Mount DFC API endpoints
    mount DfcProvider::Engine, at: '/'
  end
  
  namespace :api do
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

      resources :orders, only: [:index, :show] do
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
    end

    match '*path', to: redirect(path: "/api/v0/%{path}"), via: :all, constraints: { path: /(?!v[0-9]).+/ }
  end
end
