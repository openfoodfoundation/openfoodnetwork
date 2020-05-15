# frozen_string_literal: true

# Executes actions after checkout
module Checkout
  class PostCheckoutActions
    def initialize(order)
      @order = order
    end

    def success(controller, params, current_user)
      save_order_addresses_as_user_default(params, current_user)
      OrderCompletionReset.new(controller, @order).call
    end

    def failure
      @order.updater.shipping_address_from_distributor
      OrderCheckoutRestart.new(@order).call
    end

    private

    def save_order_addresses_as_user_default(params, current_user)
      return unless params[:order]

      user_default_address_setter = UserDefaultAddressSetter.new(@order, current_user)
      user_default_address_setter.set_default_bill_address if params[:order][:default_bill_address]
      user_default_address_setter.set_default_ship_address if params[:order][:default_ship_address]
    end
  end
end
