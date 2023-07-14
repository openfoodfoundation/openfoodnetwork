# frozen_string_literal: false

class Invoice
  class AdjustableSerializer < ActiveModel::Serializer
    attributes :id, :type, :currency, :included_tax_total, :additional_tax_total, :amount
    def type
      object.class.name
    end

    [:currency, :included_tax_total, :additional_tax_total, :amount].each do |method|
      define_method method do
        return nil unless object.respond_to?(method)

        object.public_send(method).to_f
      end
    end
  end
end
