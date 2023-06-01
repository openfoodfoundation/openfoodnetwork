# frozen_string_literal: true

module Reporting
  module Reports
    module BulkCoop
      class Base < ReportTemplate
        def message
          I18n.t("spree.admin.reports.customer_names_message.customer_names_tip")
        end

        def search
          report_line_items.orders
        end

        def table_items
          report_line_items.list(line_item_includes)
        end

        private

        def line_item_includes
          [
            {
              order: [:bill_address],
              variant: { product: :supplier }
            }
          ]
        end

        def order_permissions
          @order_permissions ||= ::Permissions::Order.new(@user)
        end

        def report_line_items
          @report_line_items ||= Reporting::LineItems.new(
            order_permissions,
            @params,
            CompleteVisibleOrders.new(order_permissions).query
          )
        end

        def empty_cell(_line_items)
          ""
        end

        def full_name(line_items)
          line_items.first.full_name
        end

        def group_buy_unit_size(line_items)
          unit_size = line_items.first.variant.product.group_buy_unit_size || 0.0
          unit_size / (line_items.first.product.variant_unit_scale || 1)
        end

        def max_quantity_excess(line_items)
          max_quantity_amount(line_items) - total_amount(line_items)
        end

        def max_quantity_amount(line_items)
          line_items.sum do |line_item|
            max_quantity = [line_item.max_quantity || 0, line_item.quantity || 0].max
            max_quantity * scaled_unit_value(line_item.variant)
          end
        end

        def scaled_unit_value(variant)
          (variant.unit_value || 0) / (variant.product.variant_unit_scale || 1)
        end

        def option_value_value(line_items)
          VariantUnits::OptionValueNamer.new(line_items.first).value
        end

        def option_value_unit(line_items)
          VariantUnits::OptionValueNamer.new(line_items.first).unit
        end

        def order_billing_address_name(line_items)
          billing_address = line_items.first.order.bill_address
          "#{billing_address.firstname} #{billing_address.lastname}"
        end

        def product_group_buy_unit_size(line_items)
          line_items.first.product.group_buy_unit_size || 0.0
        end

        def product_name(line_items)
          line_items.first.product.name
        end

        def remainder(line_items)
          remainder = total_available(line_items) - total_amount(line_items)
          remainder >= 0 ? remainder : ''
        end

        def total_amount(line_items)
          line_items.sum { |li| scaled_final_weight_volume(li) }
        end

        def scaled_final_weight_volume(line_item)
          (line_item.final_weight_volume || 0) / (line_item.product.variant_unit_scale || 1)
        end

        def total_available(line_items)
          units_required(line_items) * group_buy_unit_size(line_items)
        end

        def units_required(line_items)
          if group_buy_unit_size(line_items).zero?
            0
          else
            ( total_amount(line_items) / group_buy_unit_size(line_items) ).ceil
          end
        end

        def variant_product_group_buy_unit_size_f(line_items)
          group_buy_unit_size(line_items).to_i
        end

        def variant_product_name(line_items)
          line_items.first.variant.product.name
        end

        def weight_from_unit_value(line_items)
          line_items.first.weight_from_unit_value || 0
        end
      end
    end
  end
end
