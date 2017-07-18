class ResetOrderService < SimpleDelegator
  def call
    distributor = current_order.distributor
    token = current_order.token

    controller.expire_current_order
    build_new_order(distributor, token)
  end

  private

  def build_new_order(distributor, token)
    current_order(true)
    current_order.set_distributor!(distributor)
    current_order.tokenized_permission.token = token
    current_order.tokenized_permission.save!
  end

  def controller
    __getobj__
  end
end
