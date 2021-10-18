# frozen_string_literal: true

class Api::LineItemSerializer < ActiveModel::Serializer
  attributes :id, :quantity, :max_quantity, :price, :order_id, :tax_category_id

  has_one :variant, serializer: Api::VariantSerializer
end
