Openfoodnetwork::Application.routes.draw do
  namespace :api do
    resources :enterprises do
      post :update_image, on: :member
      get :managed, on: :collection
      get :accessible, on: :collection

      resource :logo, only: [:destroy]
      resource :promo_image, only: [:destroy]

      member do
        get :shopfront
      end
    end

    resources :order_cycles do
      get :managed, on: :collection
      get :accessible, on: :collection
    end

    resources :orders, only: [:index]

    resource :status do
      get :job_queue
    end

    resources :customers, only: [:index, :update]

    resources :enterprise_fees, only: [:destroy]

    post '/product_images/:product_id', to: 'product_images#update_product_image'
  end
end
