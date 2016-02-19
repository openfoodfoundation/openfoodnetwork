class Api::LineItemSerializer < ActiveModel::Serializer
  attributes :id, :quantity, :max_quantity, :price

  has_one :variant, serializer: Api::VariantSerializer
end
