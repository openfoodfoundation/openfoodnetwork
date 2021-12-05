# frozen_string_literal: true

module OrderCompletion
  extend ActiveSupport::Concern

  def order_completion_reset(order)
    distributor = order.distributor
    token = order.token

    expire_current_order
    build_new_order(distributor, token)

    session[:access_token] = current_order.token
    flash[:notice] = t(:order_processed_successfully)
  end

  private

  # Clears the cached order. Required for #current_order to return a new order to serve as cart.
  # See https://github.com/spree/spree/blob/1-3-stable/core/lib/spree/core/controller_helpers/order.rb#L14
  def expire_current_order
    session[:order_id] = nil
    @current_order = nil
  end

  # Builds an order setting the token and distributor of the one specified
  def build_new_order(distributor, token)
    new_order = current_order(true)
    new_order.set_distributor!(distributor)
    new_order.tokenized_permission.token = token
    new_order.tokenized_permission.save!
  end

  def order_completion_route(order)
    main_app.order_path(order, order_token: order.token)
  end
end
