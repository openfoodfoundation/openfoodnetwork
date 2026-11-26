# frozen_string_literal: true

class Api::LineItemSerializer < ActiveModel::Serializer
  attributes :id, :quantity, :max_quantity, :price, :order_id, :tax_category_id,
             :product_name

  has_one :variant, serializer: Api::VariantSerializer

  def product_name
    object.full_product_name
  end
end
