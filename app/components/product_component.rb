# frozen_string_literal: true

class ProductComponent < ViewComponentReflex::Component
  DATETIME_FORMAT = '%F %T'

  def initialize(product:, columns:)
    super
    @product = product
    @image = @product.image if product.image.present?
    @columns = columns.map do |c|
      {
        id: c[:value],
        value: column_value(c[:value])
      }
    end
  end

  # This must be define when using ProductComponent.with_collection()
  def collection_key
    @product.id
  end

  # rubocop:disable Metrics/CyclomaticComplexity, Metrics/MethodLength
  def column_value(column)
    case column
    when 'name'
      @product.name
    when 'price'
      @product.price
    when 'unit'
      "#{@product.variants.first.unit_value} #{@product.variant_unit}"
    when 'producer'
      @product.supplier.name
    when 'category'
      @product.taxons.map(&:name).join(', ')
    when 'sku'
      @product.sku
    when 'on_hand'
      @product.on_hand || 0
    when 'on_demand'
      @product.on_demand
    when 'tax_category'
      @product.variant.tax_category.name
    when 'inherits_properties'
      @product.inherits_properties
    when 'import_date'
      format_date(@product.import_date)
    end
  end
  # rubocop:enable Metrics/CyclomaticComplexity, Metrics/MethodLength

  private

  def format_date(date)
    date&.strftime(DATETIME_FORMAT) || ''
  end
end
