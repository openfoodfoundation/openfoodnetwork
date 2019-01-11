Spree::Core::Engine.routes.prepend do
  namespace :admin do
    namespace :reports do
      resource :enterprise_fee_summary, only: [:new, :create]
    end
  end
end
