Openfoodweb::Application.routes.draw do
  # Mount Spree's routes
  mount Spree::Core::Engine, :at => '/'
end


Spree::Core::Engine.routes.prepend do
  resources :suppliers
  resources :distributors do
    get :select, :on => :member
    get :deselect, :on => :collection
  end

  namespace :admin do
    resources :distributors do
      post :bulk_update, :on => :collection, :as => :bulk_update
    end
    resources :suppliers
  end
end
