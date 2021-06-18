# frozen_string_literal: true

module Api
  class PaymentSerializer < ActiveModel::Serializer
    attributes :amount, :updated_at, :payment_method, :state, :cvv_response_message

    def payment_method
      object.payment_method.try(:name)
    end

    def updated_at
      I18n.l(object.updated_at, format: "%b %d, %Y %H:%M")
    end
  end
end
