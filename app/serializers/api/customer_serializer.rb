module Api
  class CustomerSerializer < ActiveModel::Serializer
    attributes :id, :enterprise_id, :name, :code, :email, :allow_charges,
               :gateway_recurring_payment_client_secret, :gateway_shop_id
  end
end
