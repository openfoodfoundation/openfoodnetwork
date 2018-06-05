# Builds a new order based on the one specified. This implements the "continue
# shopping" feature once an order is completed.
class ResetOrderService
  # Constructor
  #
  # @param controller [#expire_current_order, #current_order]
  # @param order [Spree::Order]
  def initialize(controller, order)
    @controller = controller
    @distributor = order.distributor
    @token = order.token
  end

  # Expires the order currently in use and builds a new one based on it
  def call
    controller.expire_current_order
    build_new_order
  end

  private

  attr_reader :controller, :distributor, :token

  # Builds an order setting the token and distributor of the one specified
  def build_new_order
    new_order = controller.current_order(true)
    new_order.set_distributor!(distributor)
    new_order.tokenized_permission.token = token
    new_order.tokenized_permission.save!
  end
end
