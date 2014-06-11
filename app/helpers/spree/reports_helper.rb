module Spree
  module ReportsHelper
    def report_order_cycle_options(order_cycles)
      order_cycles.map do |oc|
        orders_open_at = oc.orders_open_at.andand.to_s(:short) || 'NA'
        orders_close_at = oc.orders_close_at.andand.to_s(:short) || 'NA'
        [ "#{oc.name} &nbsp; (#{orders_open_at} - #{orders_close_at})".html_safe, oc.id ]
      end
    end
  end
end
