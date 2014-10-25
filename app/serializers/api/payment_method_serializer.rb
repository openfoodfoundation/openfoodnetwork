class Api::PaymentMethodSerializer < ActiveModel::Serializer
  attributes :name, :description, :id, :method_type
end
