Openfoodnetwork::Application.routes.draw do
  namespace :api do
    resources :products do
      collection do
        get :bulk_products
        get :overridable
      end
      delete :soft_delete
      post :clone

      resources :variants do
        delete :soft_delete
      end
    end

    resources :variants, :only => [:index]

    resources :orders, only: [:index, :show] do
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

      member do
        get :shopfront
      end
    end

    resources :order_cycles do
      get :products, on: :member
      get :taxons, on: :member
      get :properties, on: :member
    end

    resources :exchanges, only: [:show], controller: 'exchange_products' do
      resources :products, controller: 'exchange_products', only: [:index]
    end

    resource :status do
      get :job_queue
    end

    resources :customers, only: [:index, :update]

    resources :enterprise_fees, only: [:destroy]

    post '/product_images/:product_id', to: 'product_images#update_product_image'

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
end
