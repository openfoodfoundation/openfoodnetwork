class Api::PaymentMethodSerializer < ActiveModel::Serializer
  attributes :name, :id, :method_type
end
