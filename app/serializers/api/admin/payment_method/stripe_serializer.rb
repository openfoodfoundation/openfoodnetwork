module Api::Admin::PaymentMethod
  class StripeSerializer < BaseSerializer
    attributes :preferred_enterprise_id
  end
end
