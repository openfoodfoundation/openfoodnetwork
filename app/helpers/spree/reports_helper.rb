require 'spree/money_decorator'

module Spree
  module ReportsHelper
    def report_order_cycle_options(order_cycles)
      order_cycles.map do |oc|
        orders_open_at = oc.orders_open_at.andand.to_s(:short) || 'NA'
        orders_close_at = oc.orders_close_at.andand.to_s(:short) || 'NA'
        [ "#{oc.name} &nbsp; (#{orders_open_at} - #{orders_close_at})".html_safe, oc.id ]
      end
    end

    def report_payment_method_options(orders)
      orders.map do |o|
        pm = o.payments.first.payment_method
        [pm.andand.name, pm.andand.id]
      end.uniq
    end

    def report_shipping_method_options(orders)
      orders.map do |o|
        sm = o.shipping_method
        [sm.andand.name, sm.andand.id]
      end.uniq
    end

    def xero_report_types
      [['Summary', 'summary'],
       ['Detailed', 'detailed']]
    end

    def currency_symbol
      Spree::Money.currency_symbol
    end
  end
end
