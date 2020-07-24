Openfoodnetwork::Application.routes.prepend do
  namespace :order_management do
    namespace :reports do
      resource :bulk_coop, only: [:new, :create], controller: :bulk_coop
      resource :enterprise_fee_summary, only: [:new, :create]
    end
  end
end
