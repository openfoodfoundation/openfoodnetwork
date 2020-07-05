Openfoodnetwork::Application.routes.prepend do
  namespace :order_management do
    namespace :api do
      get '/reports/:report_type(/:report_subtype)', to: 'reports#show'
    end

    namespace :reports do
      resource :bulk_coop, only: [:new, :create], controller: :bulk_coop
      resource :enterprise_fee_summary, only: [:new, :create]

      match '/:report_type(/:report_subtype)', to: 'reports#show', via: [:get, :post]
    end
  end
end
