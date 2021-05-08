Openfoodnetwork::Application.routes.draw do

  root :to => 'home#index'

  # Redirects from old URLs avoid server errors and helps search engines
  get "/enterprises", to: redirect("/")
  get "/products", to: redirect("/")
  get "/products/:id", to: redirect("/")
  get "/about_us", to: redirect(ContentConfig.footer_about_url)

  get "/login", to: redirect("/#/login")
  get '/unauthorized', :to => 'home#unauthorized', :as => :unauthorized

  get "/discourse/login", to: "discourse_sso#login"
  get "/discourse/sso", to: "discourse_sso#sso"

  get "/map", to: "map#index", as: :map
  get "/sell", to: "home#sell", as: :sell

  get "/register", to: "registration#index", as: :registration
  get "/register/auth", to: "registration#authenticate", as: :registration_auth
  post "/user/registered_email", to: "spree/users#registered_email"

  # Redirects to global website
  get "/connect", to: redirect("https://openfoodnetwork.org/#{ENV['DEFAULT_COUNTRY_CODE'].andand.downcase}/connect/")
  get "/learn", to: redirect("https://openfoodnetwork.org/#{ENV['DEFAULT_COUNTRY_CODE'].andand.downcase}/learn/")

  get "/cart", :to => "spree/orders#edit", :as => :cart
  patch "/cart", :to => "spree/orders#update", :as => :update_cart
  put "/cart/empty", :to => 'spree/orders#empty', :as => :empty_cart
  get '/orders/:id/token/:token' => 'spree/orders#show', :as => :token_order
  get '/payments/:id/authorize' => 'payments#redirect_to_authorize', as: "authorize_payment"

  resource :cart, controller: "cart" do
    post :populate
  end

  resource :shop, controller: "shop" do
    post :order_cycle
    get :order_cycle
    get :changeable_orders_alert
  end

  resources :producers, only: [:index] do
    collection do
      get :signup
    end
  end

  resources :shops, only: [:index] do
    collection do
      get :signup
    end
  end

  resources :line_items, only: [:destroy] do
    get :bought, on: :collection
  end

  resources :groups, only: [:index, :show] do
    collection do
      get :signup
    end
  end

  namespace :stripe do
    resources :callbacks, only: [:index]
    resources :webhooks, only: [:create]
  end

  get '/checkout', to: 'checkout#edit' , as: :checkout
  put '/checkout', to: 'checkout#update' , as: :update_checkout
  get '/checkout/:state', to: 'checkout#edit', as: :checkout_state
  get '/checkout/paypal_payment/:order_id', to: 'checkout#paypal_payment', as: :paypal_payment

  get 'embedded_shopfront/shopfront_session', to: 'application#shopfront_session'
  post 'embedded_shopfront/enable', to: 'application#enable_embedded_styles'
  post 'embedded_shopfront/disable', to: 'application#disable_embedded_styles'

  resources :enterprises do
    collection do
      post :search
      get :check_permalink
    end

    member do
      get :shop
      get :relatives
    end
  end
  get '/:id/shop', to: 'enterprises#shop', as: 'enterprise_shop'
  get "/enterprises/:permalink", to: redirect("/") # Legacy enterprise URL

  get 'sitemap.xml', to: 'sitemap#index', defaults: { format: 'xml' }

  unless Rails.env.production?
    # Mount DFC API endpoints
    mount DfcProvider::Engine, at: '/'
  end

  # Mount Spree's routes
  mount Spree::Core::Engine, :at => '/'
end
