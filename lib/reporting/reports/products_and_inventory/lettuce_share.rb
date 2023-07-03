# frozen_string_literal: true

module Reporting
  module Reports
    module ProductsAndInventory
      class LettuceShare < Base
        # NOTE: These are NOT to be translated, they need to be in this exact format
        # to work with LettucShare
        def custom_headers
          {
            product: "PRODUCT",
            description: "Description",
            quantity: "Qty",
            pack_size: "Pack Size",
            unit: "Unit",
            unit_price: "Unit Price",
            total: "Total",
            gst: "GST incl.",
            grower: "Grower and growing method",
            taxon: "Taxon"
          }
        end

        def columns
          {
            product: proc { |variant| variant.product.name },
            description: proc { |variant| variant.full_name },
            quantity: proc { |_variant| '' },
            pack_size: proc { |variant| VariantUnits::OptionValueNamer.new(variant).value },
            unit: proc { |variant| VariantUnits::OptionValueNamer.new(variant).unit },
            unit_price: proc { |variant| variant.price },
            total: proc { |_variant| '' },
            gst: proc { |variant| gst(variant) },
            grower: proc { |variant| grower_and_method(variant) },
            taxon: proc { |variant| variant.product.primary_taxon.name }
          }
        end

        private

        def gst(variant)
          tax_category = variant.tax_category
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
  end
end
