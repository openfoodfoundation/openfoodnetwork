# frozen_string_literal: true

module Reporting
  module Reports
    class List
      include ReportTypes

      def self.all
        new.all
      end

      def all
        {
          orders_and_distributors: [],
          bulk_coop: bulk_coop_report_types,
          payments: payments_report_types,
          orders_and_fulfillment: orders_and_fulfillment_report_types,
          customers: [],
          products_and_inventory: products_and_inventory_report_types,
          users_and_enterprises: [],
          enterprise_fee_summary:,
          order_cycle_management: order_cycle_management_report_types,
          sales_tax: sales_tax_report_types,
          xero_invoices: xero_report_types,
          packing: packing_report_types,
          revenues_by_hub: [],
          suppliers: suppliers_report_types,
        }
      end
    end
  end
end
