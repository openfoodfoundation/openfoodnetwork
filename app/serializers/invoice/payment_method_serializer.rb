# frozen_string_literal: false

class Invoice
  class PaymentMethodSerializer < ActiveModel::Serializer
    attributes :id, :name, :description
  end
end
