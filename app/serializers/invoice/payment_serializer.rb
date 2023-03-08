class Invoice::PaymentSerializer < ActiveModel::Serializer
  attributes :state, :created_at, :amount, :currency
  has_one :payment_method, serializer: Invoice::PaymentMethodSerializer

  def created_at
    object.created_at.to_s
  end
end
