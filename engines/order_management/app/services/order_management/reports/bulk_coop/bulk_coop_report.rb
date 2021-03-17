# frozen_string_literal: true

require "open_food_network/reports/line_items"

module OrderManagement
  module Reports
    module BulkCoop
      class BulkCoopReport
        REPORT_TYPES = [
          :bulk_coop_supplier_report,
          :bulk_coop_allocation,
          :bulk_coop_packing_sheets,
          :bulk_coop_customer_payments
        ].freeze

        attr_reader :params

        def initialize(user, params = {}, render_table = false)
          @params = params
          @user = user
          @render_table = render_table

          @supplier_report = BulkCoopSupplierReport.new
          @allocation_report = BulkCoopAllocationReport.new
          @filter_canceled = false
        end

        def header
          case params[:report_type]
          when "bulk_coop_supplier_report"
            @supplier_report.header
          when "bulk_coop_allocation"
            @allocation_report.header
          when "bulk_coop_packing_sheets"
            [I18n.t(:report_header_customer),
             I18n.t(:report_header_product),
             I18n.t(:report_header_variant),
             I18n.t(:report_header_sum_total)]
          when "bulk_coop_customer_payments"
            [I18n.t(:report_header_customer),
             I18n.t(:report_header_date_of_order),
             I18n.t(:report_header_total_cost),
             I18n.t(:report_header_amount_owing),
             I18n.t(:report_header_amount_paid)]
          else
            [I18n.t(:report_header_supplier),
             I18n.t(:report_header_product),
             I18n.t(:report_header_product),
             I18n.t(:report_header_bulk_unit_size),
             I18n.t(:report_header_variant),
             I18n.t(:report_header_weight),
             I18n.t(:report_header_sum_total),
             I18n.t(:report_header_sum_max_total),
             I18n.t(:report_header_units_required),
             I18n.t(:report_header_remainder)]
          end
        end

        def search
          report_line_items.orders
        end

        def table_items
          return [] unless @render_table

          report_line_items.list(line_item_includes)
        end

        def rules
          case params[:report_type]
          when "bulk_coop_supplier_report"
            @supplier_report.rules
          when "bulk_coop_allocation"
            @allocation_report.rules
          when "bulk_coop_packing_sheets"
            [{ group_by: proc { |li| li.product },
               sort_by: proc { |product| product.name } },
             { group_by: proc { |li| li.full_name },
               sort_by: proc { |full_name| full_name } },
             { group_by: proc { |li| li.order },
               sort_by: proc { |order| order.to_s } }]
          when "bulk_coop_customer_payments"
            [{ group_by: proc { |li| li.order },
               sort_by: proc { |order| order.completed_at } }]
          else
            [{ group_by: proc { |li| li.product.supplier },
               sort_by: proc { |supplier| supplier.name } },
             { group_by: proc { |li| li.product },
               sort_by: proc { |product| product.name },
               summary_columns: [proc { |lis| lis.first.product.supplier.name },
                                 proc { |lis| lis.first.product.name },
                                 proc { |lis| lis.first.product.group_buy_unit_size || 0.0 },
                                 proc { |_lis| "" },
                                 proc { |_lis| "" },
                                 proc { |lis| lis.sum { |li| li.quantity * (li.weight_from_unit_value || 0) } },
                                 proc { |lis| lis.sum { |li| (li.max_quantity || 0) * (li.weight_from_unit_value || 0) } },
                                 proc { |lis| ( (lis.first.product.group_buy_unit_size || 0).zero? ? 0 : ( lis.sum { |li| [li.max_quantity || 0, li.quantity || 0].max * (li.weight_from_unit_value || 0) } / lis.first.product.group_buy_unit_size ) ).floor },
                                 proc { |lis| lis.sum { |li| [li.max_quantity || 0, li.quantity || 0].max * (li.weight_from_unit_value || 0) } - ( ( (lis.first.product.group_buy_unit_size || 0).zero? ? 0 : ( lis.sum { |li| [li.max_quantity || 0, li.quantity || 0].max * (li.weight_from_unit_value || 0) } / lis.first.product.group_buy_unit_size ) ).floor * (lis.first.product.group_buy_unit_size || 0) ) }] },
             { group_by: proc { |li| li.full_name },
               sort_by: proc { |full_name| full_name } }]
          end
        end

        def columns
          case params[:report_type]
          when "bulk_coop_supplier_report"
            @supplier_report.columns
          when "bulk_coop_allocation"
            @allocation_report.columns
          when "bulk_coop_packing_sheets"
            [
              :order_billing_address_name,
              :product_name,
              :full_name,
              :total_quantity
            ]
          when "bulk_coop_customer_payments"
            [
              :order_billing_address_name,
              :order_completed_at,
              :customer_payments_total_cost,
              :customer_payments_amount_owed,
              :customer_payments_amount_paid
            ]
          else
            [
              :product_supplier_name,
              :product_name,
              :product_group_buy_unit_size,
              :full_name,
              :weight_from_unit_value,
              :total_quantity,
              :total_max_quantity,
              :empty_cell,
              :empty_cell
            ]
          end
        end

        private

        attr_reader :filter_canceled

        def line_item_includes
          [
            {
              order: [:bill_address],
              variant: [{ option_values: :option_type }, { product: :supplier }]
            },
            :option_values
          ]
        end

        def order_permissions
          @order_permissions ||= ::Permissions::Order.new(@user, filter_canceled)
        end

        def report_line_items
          @report_line_items ||= OpenFoodNetwork::Reports::LineItems.new(
            order_permissions,
            @params,
            CompleteVisibleOrders.new(order_permissions).query
          )
        end

        def customer_payments_total_cost(line_items)
          unique_orders(line_items).sum(&:total)
        end

        def customer_payments_amount_owed(line_items)
          if OpenFoodNetwork::FeatureToggle.enabled?(:customer_balance, @user)
            unique_orders(line_items).sum(&:new_outstanding_balance)
          else
            unique_orders(line_items).sum(&:outstanding_balance)
          end
        end

        def customer_payments_amount_paid(line_items)
          unique_orders(line_items).sum(&:payment_total)
        end

        def unique_orders(line_items)
          line_items.map(&:order).uniq
        end

        def empty_cell(_line_items)
          ""
        end

        def full_name(line_items)
          line_items.first.full_name
        end

        def group_buy_unit_size(line_items)
          (line_items.first.variant.product.group_buy_unit_size || 0.0) /
            (line_items.first.product.variant_unit_scale || 1)
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

        def option_value_value(line_items)
          VariantUnits::OptionValueNamer.new(line_items.first).value
        end

        def option_value_unit(line_items)
          VariantUnits::OptionValueNamer.new(line_items.first).unit
        end

        def order_billing_address_name(line_items)
          billing_address = line_items.first.order.bill_address
          billing_address.firstname + " " + billing_address.lastname
        end

        def order_completed_at(line_items)
          line_items.first.order.completed_at.to_s
        end

        def product_group_buy_unit_size(line_items)
          line_items.first.product.group_buy_unit_size || 0.0
        end

        def product_name(line_items)
          line_items.first.product.name
        end

        def product_supplier_name(line_items)
          line_items.first.product.supplier.name
        end

        def remainder(line_items)
          remainder = total_available(line_items) - total_amount(line_items)
          remainder >= 0 ? remainder : ''
        end

        def scaled_final_weight_volume(line_item)
          (line_item.final_weight_volume || 0) / (line_item.product.variant_unit_scale || 1)
        end

        def scaled_unit_value(variant)
          (variant.unit_value || 0) / (variant.product.variant_unit_scale || 1)
        end

        def total_amount(line_items)
          line_items.sum { |li| scaled_final_weight_volume(li) }
        end

        def total_available(line_items)
          units_required(line_items) * group_buy_unit_size(line_items)
        end

        def total_max_quantity(line_items)
          line_items.sum { |line_item| line_item.max_quantity || 0 }
        end

        def total_quantity(line_items)
          line_items.sum(&:quantity)
        end

        def total_label(_line_items)
          I18n.t('admin.reports.total')
        end

        def units_required(line_items)
          if group_buy_unit_size(line_items).zero?
            0
          else
            ( total_amount(line_items) / group_buy_unit_size(line_items) ).ceil
          end
        end

        def variant_product_group_buy_unit_size_f(line_items)
          group_buy_unit_size(line_items)
        end

        def variant_product_name(line_items)
          line_items.first.variant.product.name
        end

        def variant_product_supplier_name(line_items)
          line_items.first.variant.product.supplier.name
        end

        def weight_from_unit_value(line_items)
          line_items.first.weight_from_unit_value || 0
        end
      end
    end
  end
end
