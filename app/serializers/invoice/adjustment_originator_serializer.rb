# frozen_string_literal: false

class Invoice
  class AdjustmentOriginatorSerializer < ActiveModel::Serializer
    attributes :id, :type, :amount
    def type
      object.class.name
    end

    def amount
      return nil unless object.respond_to?(:amount)

      object.amount.to_f
    end
  end
end
