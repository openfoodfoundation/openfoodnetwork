Openfoodnetwork::Application.routes.prepend do
  namespace :order_management do
    namespace :reports do
      resource :enterprise_fee_summary, only: [:new, :create]
    end
  end
end
