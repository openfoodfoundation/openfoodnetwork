module Spree
  Shipment.class_eval do
    def ensure_correct_adjustment_with_included_tax
      ensure_correct_adjustment_without_included_tax

      adjustment.set_included_tax! Config.shipping_tax_rate if Config.shipment_inc_vat
    end

    alias_method_chain :ensure_correct_adjustment, :included_tax
  end
end
