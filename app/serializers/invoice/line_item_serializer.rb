# frozen_string_literal: false

class Invoice
  class LineItemSerializer < ActiveModel::Serializer
    attributes :id, :added_tax, :currency, :included_tax, :price_with_adjustments, :quantity,
               :variant_id, :unit_price_price_and_unit, :unit_presentation, :enterprise_fee_tax
    has_one :variant, serializer: Invoice::VariantSerializer
    has_many :tax_rates, serializer: Invoice::TaxRateSerializer

    def enterprise_fee_tax
      EnterpriseFeeAdjustments.new(object.enterprise_fee_adjustments).total_tax
    end
  end
end
