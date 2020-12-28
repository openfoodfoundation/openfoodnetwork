# frozen_string_literal: true

Openfoodnetwork::Application.routes.append do
  namespace :order_management do
    namespace :reports do
      resource :bulk_coop, only: [:new, :create], controller: :bulk_coop
      resource :enterprise_fee_summary, only: [:new, :create]
    end
  end
end
