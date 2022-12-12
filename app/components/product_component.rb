# frozen_string_literal: true

class ProductComponent < ViewComponentReflex::Component
  def initialize(product:, columns:)
    super
    @product = product
    @image = @product.images[0] if product.images.any?
    @columns = columns.map { |c|
      {
        id: c[:value],
        value: column_value(c[:value])
      }
    }
  end

  def column_value(column)
    case column
    when 'name'
      @product.name
    when 'price'
      @product.price
    when 'unit'
      "#{@product.unit_value} #{@product.variant_unit}"
    when 'producer'
      @product.supplier.name
    when 'category'
      @product.taxons.map(&:name).join(', ')
    end
  end
end
