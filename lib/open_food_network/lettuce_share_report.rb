require 'open_food_network/products_and_inventory_report_base'

module OpenFoodNetwork
  class LettuceShareReport < ProductsAndInventoryReportBase
    def header
      [
        I18n.t(:report_header_product),
        I18n.t(:report_header_description),
        I18n.t(:report_header_qty),
        I18n.t(:report_header_pack_size),
        I18n.t(:report_header_unit),
        I18n.t(:report_header_unit_price),
        I18n.t(:report_header_total),
        I18n.t(:report_header_gst_incl),
        I18n.t(:report_header_grower_and_method),
        I18n.t(:report_header_taxon)
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
        line_item = mock_line_item(variant)
        tax_rate.calculator.compute line_item
      else
        0
      end
    end

    def mock_line_item(variant)
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
