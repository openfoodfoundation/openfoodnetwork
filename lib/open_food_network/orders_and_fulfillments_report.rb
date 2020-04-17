require "open_food_network/reports/line_items"
require "open_food_network/orders_and_fulfillments_report/supplier_totals_report"
require "open_food_network/orders_and_fulfillments_report/supplier_totals_by_distributor_report"
require "open_food_network/orders_and_fulfillments_report/distributor_totals_by_supplier_report"
require "open_food_network/orders_and_fulfillments_report/customer_totals_report"
require 'open_food_network/orders_and_fulfillments_report/default_report'

include Spree::ReportsHelper

module OpenFoodNetwork
  class OrdersAndFulfillmentsReport
    attr_reader :options, :report_type

    delegate :header, :rules, :columns, to: :report

    def initialize(user, options = {}, render_table = false)
      @user = user
      @options = options
      @report_type = options[:report_type]
      @render_table = render_table
      @variant_scopers_by_distributor_id = {}
    end

    def search
      report_line_items.orders
    end

    def table_items
      return [] unless @render_table
      report_line_items.list(report.line_item_includes)
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

    def total_units(line_items)
      return " " if not_all_have_unit?(line_items)

      total_units = line_items.sum do |li|
        product = li.variant.product
        li.quantity * li.unit_value / scale_factor(product)
      end

      total_units.round(3)
    end

    def not_all_have_unit?(line_items)
      line_items.map { |li| li.unit_value.nil? }.any?
    end

    def scale_factor(product)
      product.variant_unit == 'weight' ? 1000 : 1
    end

    def order_permissions
      return @order_permissions unless @order_permissions.nil?
      @order_permissions = ::Permissions::Order.new(@user, options[:q])
    end

    def report_line_items
      @report_line_items ||= Reports::LineItems.new(order_permissions, options)
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
