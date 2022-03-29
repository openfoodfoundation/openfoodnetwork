# frozen_string_literal: true

# require 'variant_units/option_value_namer'

module Reporting
  module Reports
    module ProductsAndInventory
      class LettuceShareReport
        attr_reader :context

        delegate :variants, :render_table, to: :context

        def initialize(context)
          @context = context
        end

        def table_headers
          # NOTE: These are NOT to be translated, they need to be in this exact format to work with LettucShare
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

        def table_rows
          return [] unless render_table

          variants.select(&:in_stock?)
            .map do |variant|
            [
              variant.product.name,
              variant.full_name,
              '',
              VariantUnits::OptionValueNamer.new(variant).value,
              VariantUnits::OptionValueNamer.new(variant).unit,
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
  end
end
