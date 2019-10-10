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

    def initialize(permissions, options = {}, render_table = false)
      @options = options
      @report_type = options[:report_type]
      @permissions = permissions
      @render_table = render_table
    end

    def header
      case report_type
      when SupplierTotalsReport::REPORT_TYPE
        SupplierTotalsReport.new(self).header
      when SupplierTotalsByDistributorReport::REPORT_TYPE
        SupplierTotalsByDistributorReport.new(self).header
      when DistributorTotalsBySupplierReport::REPORT_TYPE
        DistributorTotalsBySupplierReport.new(self).header
      when CustomerTotalsReport::REPORT_TYPE
        CustomerTotalsReport.new(self).header
      else
        DefaultReport.new(self).header
      end
    end

    def search
      Reports::LineItems.search_orders(permissions, options)
    end

    def table_items
      return [] unless @render_table
      Reports::LineItems.list(permissions, options)
    end

    def rules
      case report_type
      when SupplierTotalsReport::REPORT_TYPE
        SupplierTotalsReport.new(self).rules
      when SupplierTotalsByDistributorReport::REPORT_TYPE
        SupplierTotalsByDistributorReport.new(self).rules
      when DistributorTotalsBySupplierReport::REPORT_TYPE
        DistributorTotalsBySupplierReport.new(self).rules
      when CustomerTotalsReport::REPORT_TYPE
        CustomerTotalsReport.new(self).rules
      else
        DefaultReport.new(self).rules
      end
    end

    # Returns a proc for each column displayed in each report type containing
    # the logic to compute the value for each cell.
    def columns
      case report_type
      when SupplierTotalsReport::REPORT_TYPE
        SupplierTotalsReport.new(self).columns
      when SupplierTotalsByDistributorReport::REPORT_TYPE
        SupplierTotalsByDistributorReport.new(self).columns
      when DistributorTotalsBySupplierReport::REPORT_TYPE
        DistributorTotalsBySupplierReport.new(self).columns
      when CustomerTotalsReport::REPORT_TYPE
        CustomerTotalsReport.new(self).columns
      else
        DefaultReport.new(self).columns
      end
    end

    private

    attr_reader :permissions

    def supplier_name
      proc { |line_items| line_items.first.variant.product.supplier.name }
    end

    def product_name
      proc { |line_items| line_items.first.variant.product.name }
    end

    def line_item_name
      proc { |line_item| line_item.variant.full_name }
    end

    def line_items_name
      proc { |line_items| line_items.first.variant.full_name }
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
  end
end
