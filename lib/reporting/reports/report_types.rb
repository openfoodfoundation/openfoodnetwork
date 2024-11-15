# frozen_string_literal: true

module Reporting
  module Reports
    module ReportTypes
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
          [i18n_translate("inventory"), :inventory, { deprecated: true }],
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

      def enterprise_fee_summary
        [
          [i18n_translate('enterprise_fee_summary.name'), :fee_summary],
          [
            i18n_translate('enterprise_fees_with_tax_report_by_order'),
            :enterprise_fees_with_tax_report_by_order
          ],
          [
            i18n_translate('enterprise_fees_with_tax_report_by_producer'),
            :enterprise_fees_with_tax_report_by_producer
          ],
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

      def suppliers_report_types
        [
          [i18n_translate(:pay_your_suppliers), :pay_your_suppliers]
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
