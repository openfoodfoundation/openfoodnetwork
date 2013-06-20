Openfoodweb::Application.routes.draw do
  root :to => 'spree/home#index'

  resources :enterprises do
    get :suppliers, :on => :collection
    get :distributors, :on => :collection
  end

  namespace :admin do
    resources :order_cycles do
      post :bulk_update, :on => :collection, :as => :bulk_update
    end

    resources :enterprises do
      post :bulk_update, :on => :collection, :as => :bulk_update
    end

    resources :enterprise_fees do
      post :bulk_update, :on => :collection, :as => :bulk_update
    end
  end

  # Mount Spree's routes
  mount Spree::Core::Engine, :at => '/'
end


Spree::Core::Engine.routes.prepend do
  match '/admin/reports/orders_and_distributors' => 'admin/reports#orders_and_distributors', :as => "orders_and_distributors_admin_reports",  :via  => [:get, :post]
  match '/admin/reports/group_buys' => 'admin/reports#group_buys', :as => "group_buys_admin_reports",  :via  => [:get, :post]
  match '/admin/reports/bulk_coop' => 'admin/reports#bulk_coop', :as => "bulk_coop_admin_reports",  :via  => [:get, :post]
  match '/admin/reports/payments' => 'admin/reports#payments', :as => "payments_admin_reports",  :via  => [:get, :post]
  match '/admin/reports/order_cycles' => 'admin/reports#order_cycles', :as => "order_cycles_admin_reports",  :via  => [:get, :post]
  match '/admin/products/bulk_edit' => 'admin/products#bulk_edit', :as => "bulk_edit_admin_products"

  namespace :admin do
    resources :products do
      get :bulk_index, :on => :collection, :as => :bulk_index
      post :bulk_update, :on => :collection, :as => :bulk_update
    end
  end

  resources :orders do
    get :select_distributor, :on => :member
    get :deselect_distributor, :on => :collection
  end
end
