Spree::OrderUpdater.class_eval do
  # Override spree method to make it update all adjustments as in Spree v2.0.4
  def update_shipping_adjustments
    order.adjustments.reload.each { |adjustment| adjustment.update! }
  end
end
