# frozen_string_literal: true

module Reporting
  module Reports
    module OrdersAndFulfillment
      class Base < ReportTemplate
        def message
          I18n.t("spree.admin.reports.customer_names_message.customer_names_tip")
        end

        def default_params
          {
            fields_to_hide: [:producer_charges_sales_tax?, :product_tax_category],
            q: {
              completed_at_gt: 1.month.ago.beginning_of_day,
              completed_at_lt: 1.day.from_now.beginning_of_day
            }
          }
        end

        def search
          report_line_items.orders
        end

        def query_result
          report_line_items.list(line_item_includes).group_by { |e|
            [e.variant_id, e.price, e.order.distributor_id]
          }.values
        end

        private

        def order_permissions
          return @order_permissions unless @order_permissions.nil?

          @order_permissions = ::Permissions::Order.new(@user, ransack_params)
        end

        def report_line_items
          @report_line_items ||= Reporting::LineItems.new(order_permissions, params)
        end

        def variant_name
          proc { |line_items| line_items.first.variant.full_name }
        end

        def variant_sku
          proc { |line_items| line_items.first.variant.sku }
        end

        def supplier_name
          proc { |line_items| line_items.first.variant.product.supplier.name }
        end

        def supplier_charges_sales_tax?
          proc { |line_items| line_items.first.variant.product.supplier.charges_sales_tax }
        end

        def product_name
          proc { |line_items| line_items.first.variant.product.name }
        end

        def product_tax_category
          proc { |line_items| line_items.first.variant.tax_category&.name }
        end

        def hub_name
          proc { |line_items| line_items.first.order.distributor.name }
        end

        def total_units(line_items)
          return " " if not_all_have_unit?(line_items)

          total_units = line_items.sum do |li|
            product = li.variant.product
            li.quantity * li.unit_value / scale_factor(product)
          end

          total_units.round(3)
        end

        def variant_scoper_for(distributor_id)
          @variant_scopers_by_distributor_id ||= {}
          @variant_scopers_by_distributor_id[distributor_id] ||=
            OpenFoodNetwork::ScopeVariantToHub.new(
              distributor_id,
              report_variant_overrides[distributor_id] || {},
            )
        end

        def not_all_have_unit?(line_items)
          line_items.map { |li| li.unit_value.nil? }.any?
        end

        def scale_factor(product)
          product.variant_unit == 'weight' ? 1000 : 1
        end

        def report_variant_overrides
          @report_variant_overrides ||=
            VariantOverridesIndexed.new(
              order_permissions.visible_line_items.select('DISTINCT variant_id'),
              report_line_items.orders.result.select('DISTINCT distributor_id'),
            ).indexed
        end
      end
    end
  end
end
