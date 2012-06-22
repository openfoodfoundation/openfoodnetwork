Openfoodweb::Application.routes.draw do
  # Mount Spree's routes
  mount Spree::Core::Engine, :at => '/'
end


Spree::Core::Engine.routes.prepend do
  resources :suppliers
  resources :distributors do
    get :select, :on => :member
  end

  namespace :admin do
    resources :distributors
    resources :suppliers
  end
end
