class Invoice::PaymentMethodSerializer < ActiveModel::Serializer
  attributes :id, :name, :description
end
