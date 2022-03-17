# frozen_string_literal: true

class ProductComponent < ViewComponentReflex::Component
  def initialize(product:, columns:)
    @columns = columns
    @image = product.images[0] if product.images.any?
    @name = product.name
    @unit = "#{product.unit_value}  #{product.variant_unit}"
    @price = product.price
  end
end
