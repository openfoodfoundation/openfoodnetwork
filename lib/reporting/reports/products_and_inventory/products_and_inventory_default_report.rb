# frozen_string_literal: true

module Reporting
  module Reports
    module ProductsAndInventory
      class ProductsAndInventoryDefaultReport
        attr_reader :context

        delegate :variants, :render_table, to: :context

        def initialize(context)
          @context = context
        end

        def table_headers
          [
            I18n.t(:report_header_supplier),
            I18n.t(:report_header_producer_suburb),
            I18n.t(:report_header_product),
            I18n.t(:report_header_product_properties),
            I18n.t(:report_header_taxons),
            I18n.t(:report_header_variant_value),
            I18n.t(:report_header_price),
            I18n.t(:report_header_group_buy_unit_quantity),
            I18n.t(:report_header_amount),
            I18n.t(:report_header_sku)
          ]
        end

        def table_rows
          variants.map do |variant|
            [
              variant.product.supplier.name,
              variant.product.supplier.address.city,
              variant.product.name,
              variant.product.properties.map(&:name).join(", "),
              variant.product.taxons.map(&:name).join(", "),
              variant.full_name,
              variant.price,
              variant.product.group_buy_unit_size,
              "",
              sku_for(variant)
            ]
          end
        end

        def sku_for(variant)
          return variant.sku if variant.sku.present?

          variant.product.sku
        end
      end
    end
  end
end
