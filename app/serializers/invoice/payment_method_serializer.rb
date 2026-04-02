# frozen_string_literal: false

class Invoice
  class PaymentMethodSerializer < ActiveModel::Serializer
    attributes :id, :display_name, :display_description
  end
end
