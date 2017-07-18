class ResetOrderService
  def initialize(controller, order)
    @controller = controller
    @distributor = order.distributor
    @token = order.token
  end

  def call
    controller.expire_current_order
    build_new_order
  end

  private

  attr_reader :controller, :distributor, :token

  def build_new_order
    new_order = controller.current_order(true)
    new_order.set_distributor!(distributor)
    new_order.tokenized_permission.token = token
    new_order.tokenized_permission.save!
  end
end
