module Spree
  module ReportsHelper
    def report_order_cycle_options(order_cycles)
      order_cycles.map do |oc|
        orders_open_at = oc.orders_open_at.andand.to_s(:short) || 'NA'
        orders_close_at = oc.orders_close_at.andand.to_s(:short) || 'NA'
        [ "#{oc.name} &nbsp; (#{orders_open_at} - #{orders_close_at})".html_safe, oc.id ]
      end
    end

    #lin-d-hop
    #Find the payment methods options for reporting. 
    #I don't like that this is done in two loops, but redundant list entries
    #  were created otherwise... 
    def report_payment_method_options(orders)
      payment_method_list = {}
      orders.map do |o|
        payment_method_name = o.payments.first.payment_method.andand.name
        payment_method_id = o.payments.first.payment_method.andand.id
        payment_method_list[payment_method_name] = payment_method_id
      end
      payment_method_list.each do |key, value|
        [ "#{value}".html_safe,  key]
      end
    end

    

  end
end
