require 'open_food_network/products_and_inventory_report_base'

module OpenFoodNetwork
  class LettuceShareReport < ProductsAndInventoryReportBase
    def header
      [
        "PRODUCT",
        "Description",
        "Qty",
        "Pack Size",
        "Unit",
        "Unit Price",
        "Total",
        "GST incl.",
        "Grower and growing method",
        "Taxon"
      ]
    end

    def table
      variants.select { |v| v.in_stock? }
      .map do |variant|
        [
          variant.product.name,
          variant.full_name,
          '',
          OptionValueNamer.new(variant).value,
          OptionValueNamer.new(variant).unit,
          variant.price,
          '',
          gst(variant),
          grower_and_method(variant),
          variant.product.primary_taxon.name
        ]
      end
    end


    private

    def gst(variant)
      tax_category = variant.product.tax_category
      if tax_category && tax_category.tax_rates.present?
        tax_rate = tax_category.tax_rates.first
        line_item = mock_line_item(variant, tax_category)
        tax_rate.calculator.compute line_item
      else
        0
      end
    end

    def mock_line_item(variant, tax_category)
      product = OpenStruct.new tax_category: tax_category
      line_item = Spree::LineItem.new quantity: 1
      line_item.define_singleton_method(:product) { variant.product }
      line_item.define_singleton_method(:price) { variant.price }
      line_item
    end

    def grower_and_method(variant)
      cert = certification(variant)

      result  = producer_name(variant)
      result += " (#{cert})" if cert.present?
      result
    end

    def producer_name(variant)
      variant.product.supplier.name
    end

    def certification(variant)
      variant.product.properties_including_inherited.map do |p|
        "#{p[:name]} - #{p[:value]}"
      end.join(', ')
    end

  end
end
