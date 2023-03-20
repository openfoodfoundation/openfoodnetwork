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
  resources :locales, only: [:show]

  # Redirects to global website
  get "/connect", to: redirect("https://openfoodnetwork.org/#{ENV['DEFAULT_COUNTRY_CODE']&.downcase}/connect/")
  get "/learn", to: redirect("https://openfoodnetwork.org/#{ENV['DEFAULT_COUNTRY_CODE']&.downcase}/learn/")

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

  # Temporary re-routing for any pending Stripe payments still using the old return URLs
  constraints ->(request) { request["payment_intent"]&.start_with?("pm_") } do
    match "/checkout", via: :get, controller: "payment_gateways/stripe", action: "confirm"
    match "/orders/:order_number", via: :get, controller: "payment_gateways/stripe", action: "authorize"
  end

  namespace :payment_gateways do
    get "/paypal", to: "paypal#express", as: :paypal_express
    get "/paypal/confirm", to: "paypal#confirm", as: :confirm_paypal
    get "/paypal/cancel", to: "paypal#cancel", as: :cancel_paypal

    get "/stripe/confirm", to: "stripe#confirm", as: :confirm_stripe
    get "/stripe/authorize/:order_number", to: "stripe#authorize", as: :authorize_stripe
  end

  constraints FeatureToggleConstraint.new(:split_checkout) do
    get '/checkout', to: 'split_checkout#edit'

    constraints step: /(details|payment|summary)/ do
      get '/checkout/:step', to: 'split_checkout#edit', as: :checkout_step
      put '/checkout/:step', to: 'split_checkout#update', as: :checkout_update
    end

    delete '/checkout/payment', to: 'split_checkout#destroy', as: :checkout_destroy

    # Redirects to the new checkout for any other 'step' (ie. /checkout/cart from the legacy checkout)
    get '/checkout/:other', to: redirect('/checkout')
  end

   # When the split_checkout feature is disabled for the current user, use the legacy checkout
  constraints FeatureToggleConstraint.new(:split_checkout, negate: true) do
    get '/checkout', to: 'checkout#edit'
    put '/checkout', to: 'checkout#update', as: :update_checkout
    get '/checkout/:state', to: 'checkout#edit', as: :checkout_state
  end

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

  # Mount Spree's routes
  mount Spree::Core::Engine, :at => '/'

  # Errors controller
  match '/404' => 'errors#not_found', via: :all
  match '/500' => 'errors#internal_server_error', via: :all
  match '/422' => 'errors#unprocessable_entity', via: :all
end
