require 'open_food_network/user_balance_calculator'

module OpenFoodNetwork
  class OrderCycleManagementReport
    attr_reader :params

    def initialize(user, params = {})
      @params = params
      @user = user
    end

    def header
      if is_payment_methods?
        ["First Name", "Last Name", "Hub", "Hub Code", "Email", "Phone", "Shipping Method", "Payment Method", "Amount", "Balance"]
      else
        ["First Name", "Last Name", "Hub", "Hub Code", "Delivery Address", "Delivery Postcode", "Phone", "Shipping Method", "Payment Method", "Amount", "Balance", "Temp Controlled Items?", "Special Instructions"]
      end
    end

    def search
      Spree::Order
        .eager_load(shipments: :shipping_method)
        .complete
        .where("spree_orders.state != ?", :canceled)
        .distributed_by_user(@user)
        .managed_by(@user)
        .search(params[:q])
    end

    def orders
      filter search.result
    end

    def table_items
      if is_payment_methods?
        orders.map { |o| payment_method_row o }
      else
        orders.map { |o| delivery_row o }
      end
    end

    def filter(search_result)
      filtered_orders = filter_to_order_cycle(search_result)
      filtered_orders = filter_to_shipping_method(filtered_orders)
      filter_to_payment_method(filtered_orders)
    end

    private

    def payment_method_row(order)
      billing_address = order.billing_address
      [
        billing_address.firstname,
        billing_address.lastname,
        order.distributor.andand.name,
        customer_code(order.email),
        order.email,
        billing_address.phone,
        shipping_method_to_display(order).name,
        order.payments.first.andand.payment_method.andand.name,
        order.payments.first.amount,
        OpenFoodNetwork::UserBalanceCalculator.new(order.email, order.distributor).balance
      ]
    end

    def delivery_row(order)
      shipping_address = order.shipping_address
      [
        shipping_address.firstname,
        shipping_address.lastname,
        order.distributor.andand.name,
        customer_code(order.email),
        "#{shipping_address.address1} #{shipping_address.address2} #{shipping_address.city}",
        shipping_address.zipcode,
        shipping_address.phone,
        shipping_method_to_display(order).name,
        order.payments.first.andand.payment_method.andand.name,
        order.payments.first.amount,
        OpenFoodNetwork::UserBalanceCalculator.new(order.email, order.distributor).balance,
        has_temperature_controlled_items?(order),
        order.special_instructions
      ]
    end

    # Returns the appropriate shipping method to display for the given order
    #
    # @param order [Spree::Order]
    # @return [#name]
    def shipping_method_to_display(order)
      shipment = order.shipments.last
      if shipment
        shipment.shipping_method
      else
        NullShippingMethod.new
      end
    end

    def filter_to_payment_method(orders)
      if params[:payment_method_in].present?
        orders.joins(payments: :payment_method).where(spree_payments: { payment_method_id: params[:payment_method_in]})
      else
        orders
      end
    end

    def filter_to_shipping_method(orders)
      if params[:shipping_method_in].present?
        orders.where(spree_shipments: { shipping_method_id: params[:shipping_method_in] })
      else
        orders
      end
    end

    def filter_to_order_cycle(orders)
      if params[:order_cycle_id].present?
        orders.where(order_cycle_id: params[:order_cycle_id])
      else
        orders
      end
    end

    def has_temperature_controlled_items?(order)
      order.line_items.any? { |line_item| line_item.product.shipping_category.andand.temperature_controlled }
    end

    def is_payment_methods?
      params[:report_type] == "payment_methods"
    end

    def customer_code(email)
      customer = Customer.where(email: email).first
      customer.nil? ? "" : customer.code
    end
  end
end
