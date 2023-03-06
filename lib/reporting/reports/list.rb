# frozen_string_literal: true

module Reporting
  module Reports
    class List
      def self.all
        new.all
      end

      def all
        {
          orders_and_distributors: [],
          bulk_coop: bulk_coop_report_types,
          payments: payments_report_types,
          orders_and_fulfillment: orders_and_fulfillment_report_types,
          customers: customers_report_types,
          products_and_inventory: products_and_inventory_report_types,
          users_and_enterprises: [],
          enterprise_fee_summary: [],
          order_cycle_management: order_cycle_management_report_types,
          sales_tax: sales_tax_report_types,
          xero_invoices: xero_report_types,
          packing: packing_report_types,
          revenues_by_hub: [],
        }
      end

      protected

      def orders_and_fulfillment_report_types
        [
          [i18n_translate("supplier_totals"), :order_cycle_supplier_totals],
          [i18n_translate("supplier_totals_by_distributor"),
           :order_cycle_supplier_totals_by_distributor],
          [i18n_translate("totals_by_supplier"), :order_cycle_distributor_totals_by_supplier],
          [i18n_translate("customer_totals"), :order_cycle_customer_totals]
        ]
      end

      def products_and_inventory_report_types
        [
          [i18n_translate("all_products"), :all_products],
          [i18n_translate("inventory"), :inventory],
          [i18n_translate("lettuce_share"), :lettuce_share]
        ]
      end

      def payments_report_types
        [
          [I18n.t(:report_payment_by), :payments_by_payment_type],
          [I18n.t(:report_itemised_payment), :itemised_payment_totals],
          [I18n.t(:report_payment_totals), :payment_totals]
        ]
      end

      def customers_report_types
        [
          [i18n_translate("mailing_list"), :mailing_list],
          [i18n_translate("addresses"), :addresses]
        ]
      end

      def order_cycle_management_report_types
        [
          [i18n_translate("payment_methods"), :payment_methods],
          [i18n_translate("delivery"), :delivery]
        ]
      end

      def sales_tax_report_types
        [
          [i18n_translate("tax_types"), :tax_types],
          [i18n_translate("tax_rates"), :tax_rates],
          [i18n_translate("sales_tax_totals_by_producer"), :sales_tax_totals_by_producer],
          [i18n_translate("sales_tax_totals_by_order"), :sales_tax_totals_by_order]
        ]
      end

      def packing_report_types
        [
          [i18n_translate("pack_by_customer"), :customer],
          [i18n_translate("pack_by_supplier"), :supplier],
          [i18n_translate("pack_by_product"), :product]
        ]
      end

      def xero_report_types
        [
          [I18n.t(:summary), 'summary'],
          [I18n.t(:detailed), 'detailed']
        ]
      end

      def bulk_coop_report_types
        [
          bulk_coop_item(:supplier_report),
          bulk_coop_item(:allocation),
          bulk_coop_item(:packing_sheets),
          bulk_coop_item(:customer_payments)
        ]
      end

      def bulk_coop_item(key)
        [I18n.t("order_management.reports.bulk_coop.filters.bulk_coop_#{key}"), key]
      end

      def i18n_translate(key)
        I18n.t(key, scope: "admin.reports")
      end
    end
  end
end
