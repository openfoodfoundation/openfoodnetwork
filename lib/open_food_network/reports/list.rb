# frozen_string_literal: true

module OpenFoodNetwork
  module Reports
    class List
      def self.all
        new.all
      end

      def all
        {
          orders_and_fulfillment: orders_and_fulfillment_report_types,
          products_and_inventory: products_and_inventory_report_types,
          customers: customers_report_types,
          enterprise_fee_summary: enterprise_fee_summary_report_types,
          order_cycle_management: order_cycle_management_report_types,
          sales_tax: sales_tax_report_types,
          packing: packing_report_types
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

      def customers_report_types
        [
          [i18n_translate("mailing_list"), :mailing_list],
          [i18n_translate("addresses"), :addresses]
        ]
      end

      def enterprise_fee_summary_report_types
        [
          [i18n_translate("enterprise_fee_summary"), :enterprise_fee_summary]
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
          [i18n_translate("tax_rates"), :tax_rates]
        ]
      end

      def packing_report_types
        [
          [i18n_translate("pack_by_customer"), :pack_by_customer],
          [i18n_translate("pack_by_supplier"), :pack_by_supplier]
        ]
      end

      def i18n_translate(key)
        I18n.t(key, scope: "admin.reports")
      end
    end
  end
end
