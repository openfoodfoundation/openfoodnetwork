# frozen_string_literal: false

class Invoice
  class PaymentSerializer < ActiveModel::Serializer
    attributes :state, :created_at, :amount, :currency, :payment_method_id
    has_one :payment_method, serializer: Invoice::PaymentMethodSerializer

    def created_at
      object.created_at.to_s
    end
  end
end
