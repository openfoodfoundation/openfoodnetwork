class ResetOrderService < SimpleDelegator
  def call
    distributor = current_order.distributor
    token = current_order.token

    session[:order_id] = nil
    __getobj__.instance_variable_set(:@current_order, nil)
    current_order(true)

    current_order.set_distributor!(distributor)
    current_order.tokenized_permission.token = token
    current_order.tokenized_permission.save!
    session[:access_token] = token
  end
end
