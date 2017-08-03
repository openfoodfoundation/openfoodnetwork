module Api
  class PaymentSerializer < ActiveModel::Serializer
    attributes :amount, :updated_at, :payment_method, :state
    def payment_method
      object.payment_method.try(:name)
    end

    def amount
      object.amount.to_money.to_s
    end

    def updated_at
      I18n.l(object.updated_at, format: "%b %d, %Y %H:%M")
    end
  end
end
