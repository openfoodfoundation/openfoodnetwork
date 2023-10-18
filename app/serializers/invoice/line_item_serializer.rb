# frozen_string_literal: false

class Invoice
  class LineItemSerializer < ActiveModel::Serializer
    attributes :id, :added_tax, :currency, :included_tax, :price_with_adjustments, :quantity,
               :variant_id, :unit_price_price_and_unit, :unit_presentation
    has_one :variant, serializer: Invoice::VariantSerializer
    has_many :tax_rates, serializer: Invoice::TaxRateSerializer
  end
end
