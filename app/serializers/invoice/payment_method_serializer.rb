class Invoice::PaymentMethodSerializer < ActiveModel::Serializer
  attributes :name, :description
end
