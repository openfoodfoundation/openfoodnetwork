# frozen_string_literal: false

class Invoice
  class LineItemSerializer < ActiveModel::Serializer
    attributes :id, :added_tax, :currency, :included_tax, :price_with_adjustments, :quantity,
               :variant_id
    has_one :variant, serializer: Invoice::VariantSerializer
  end
end
