# Resets the passed order to cart state while clearing associated payments and shipments
class RestartCheckout
  def initialize(order)
    @order = order
  end

  def restart_checkout
    return if @order.state == 'cart'
    @order.restart_checkout! # resets state to 'cart'
    @order.update_attributes!(shipping_method_id: nil)
    @order.shipments.with_state(:pending).destroy_all
    @order.payments.with_state(:checkout).destroy_all
    @order.reload
  end
end
