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
        ["First Name", "Last Name", "Email", "Phone", "Hub", "Shipping Method", "Payment Method", "Amount", "Balance"]
      else
        ["First Name", "Last Name", "Delivery Address", "Delivery Postcode", "Phone", "Hub", "Shipping Method", "Payment Method", "Amount", "Balance"]
      end
    end

    def table
      if is_payment_methods?
        orders.map { |o| payment_method_row o }
      else
        orders.map { |o| delivery_row o }
      end     
    end 

    def orders
      filter Spree::Order.managed_by(@user).distributed_by_user(@user).complete.where("spree_orders.state != ?", :canceled)
    end

    private 

    def payment_method_row (order)
      ba = order.billing_address
      da = order.distributor.andand.address
      [ba.firstname,
       ba.lastname,
       order.email,
       ba.phone,
       order.distributor.andand.name,
       order.shipping_method.andand.name,
       order.payments.first.andand.payment_method.andand.name,
       order.payments.first.amount,
       OpenFoodNetwork::UserBalanceCalculator.new(order.user, order.distributor).balance
      ]
    end

    def delivery_row (order)
      ba = order.billing_address
      da = order.distributor.andand.address
      [ba.firstname,
       ba.lastname,
       "#{ba.address1} #{ba.address2} #{ba.city}",
       ba.zipcode,
       ba.phone,
       order.distributor.andand.name,
       order.shipping_method.andand.name,
       order.payments.first.andand.payment_method.andand.name,
       order.payments.first.amount,
       OpenFoodNetwork::UserBalanceCalculator.new(order.user, order.distributor).balance
      ]
    end

    def filter(orders)
      filter_to_order_cycle filter_to_payment_method filter_to_shipping_method orders
    end

    def filter_to_payment_method(orders)
      if params[:payment_method_name].present?
        orders.with_payment_method_name(params[:payment_method_name])
      else
        orders
      end
    end

    def filter_to_shipping_method(orders)
      if params[:shipping_method_name].present?
        orders.joins(:shipping_method).where("spree_shipping_methods.name = ?", params[:shipping_method_name])
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

    def is_payment_methods?
      params[:report_type] == "payment_methods"
    end
  end
end
