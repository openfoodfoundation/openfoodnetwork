class Invoice::LineItemSerializer < ActiveModel::Serializer
  attributes :quantity, 
  :price_with_adjustments,
  :added_tax,
  :included_tax

   has_one :variant, serializer: Invoice::VariantSerializer
end
