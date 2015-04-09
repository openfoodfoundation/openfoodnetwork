module Spree
  Shipment.class_eval do
    def ensure_correct_adjustment_with_included_tax
      ensure_correct_adjustment_without_included_tax

      if Config.shipment_inc_vat && (order.distributor.nil? || order.distributor.charges_sales_tax)
        adjustment.set_included_tax! Config.shipping_tax_rate
      else
        adjustment.set_included_tax! 0
      end
    end

    alias_method_chain :ensure_correct_adjustment, :included_tax
  end
end
