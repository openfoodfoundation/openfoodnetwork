# frozen_string_literal: true

class ProductComponent < ViewComponentReflex::Component
  DATETIME_FORMAT = '%F %T'

  def initialize(product:, columns:)
    super
    @product = product
    @image = @product.images[0] if product.images.any?
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

  def column_value(column)
    # unless it is a column that needs specific formatting, we just use the product method
    return @product.public_send(column.to_sym) if use_product_method?(column)

    case column
    when 'unit'
      "#{@product.unit_value} #{@product.variant_unit}"
    when 'producer'
      @product.supplier.name
    when 'category'
      @product.taxons.map(&:name).join(', ')
    when 'on_hand'
      return 0 if @product.on_hand.nil?

      @product.on_hand
    when 'tax_category'
      @product.tax_category.name
    when 'available_on'
      format_date(@product.available_on)
    when 'import_date'
      format_date(@product.import_date)
    end
  end

  private

  def use_product_method?(column)
    # columns that need some specific formatting
    exceptions = %w[on_hand tax_category available_on import_date]

    @product.respond_to?(column.to_sym) && !exceptions.include?(column)
  end

  def format_date(date)
    return '' if date.nil?

    date.strftime(DATETIME_FORMAT)
  end
end
