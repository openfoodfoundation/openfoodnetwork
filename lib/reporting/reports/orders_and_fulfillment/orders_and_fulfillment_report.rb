# frozen_string_literal: true

module Reporting
  module Reports
    module OrdersAndFulfillment
      class OrdersAndFulfillmentReport < ReportObjectTemplate
        include ReportsHelper

        attr_reader :report_type

        delegate :table_headers, :rules, :columns, to: :report

        def initialize(user, params = {})
          super(user, params)
          @report_type = params[:report_subtype]
          @variant_scopers_by_distributor_id = {}
          now = Time.zone.now
          params[:q] ||= {
            completed_at_gt: (now - 1.month).beginning_of_day,
            completed_at_lt: (now + 1.day).beginning_of_day
          }
        end

        def message
          I18n.t("spree.admin.reports.customer_names_message.customer_names_tip")
        end

        def search
          report_line_items.orders
        end

        def table_items
          report_line_items.list(report.line_item_includes)
        end

        def table_rows
          order_grouper = Reporting::OrderGrouper.new report.rules, report.columns, report
          order_grouper.table(table_items)
        end

        def line_item_name
          proc { |line_item| line_item.variant.full_name }
        end

        def line_items_name
          proc { |line_items| line_items.first.variant.full_name }
        end

        def supplier_name
          proc { |line_items| line_items.first.variant.product.supplier.name }
        end

        def product_name
          proc { |line_items| line_items.first.variant.product.name }
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
          @variant_scopers_by_distributor_id[distributor_id] ||=
            OpenFoodNetwork::ScopeVariantToHub.new(
              distributor_id,
              report_variant_overrides[distributor_id] || {},
            )
        end

        private

        def report
          @report ||= report_klass.new(self)
        end

        def report_klass
          case report_type
          when SupplierTotalsReport::REPORT_TYPE then SupplierTotalsReport
          when SupplierTotalsByDistributorReport::REPORT_TYPE then SupplierTotalsByDistributorReport
          when DistributorTotalsBySupplierReport::REPORT_TYPE then DistributorTotalsBySupplierReport
          when CustomerTotalsReport::REPORT_TYPE then CustomerTotalsReport
          else
            DefaultReport
          end
        end

        def not_all_have_unit?(line_items)
          line_items.map { |li| li.unit_value.nil? }.any?
        end

        def scale_factor(product)
          product.variant_unit == 'weight' ? 1000 : 1
        end

        def order_permissions
          return @order_permissions unless @order_permissions.nil?

          @order_permissions = ::Permissions::Order.new(@user, params[:q])
        end

        def report_line_items
          @report_line_items ||= Reporting::LineItems.new(order_permissions, params)
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
