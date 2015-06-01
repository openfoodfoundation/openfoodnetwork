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
      Spree::Order.complete.where("spree_orders.state != ?", :canceled).managed_by(@user).search(params[:q])
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
      filter_to_payment_method filter_to_shipping_method search_result
    end


    private

    def payment_method_row(order)
      ba = order.billing_address
      da = order.distributor.andand.address
      [ba.firstname,
       ba.lastname,
       order.distributor.andand.name,
       customer_code(order.email),
       order.email,
       ba.phone,
       order.shipping_method.andand.name,
       order.payments.first.andand.payment_method.andand.name,
       order.payments.first.amount,
       OpenFoodNetwork::UserBalanceCalculator.new(order.user, order.distributor).balance
      ]
    end

    def delivery_row(order)
      ba = order.billing_address
      da = order.distributor.andand.address
      [ba.firstname,
       ba.lastname,
       order.distributor.andand.name,
       customer_code(order.email),
       "#{ba.address1} #{ba.address2} #{ba.city}",
       ba.zipcode,
       ba.phone,
       order.shipping_method.andand.name,
       order.payments.first.andand.payment_method.andand.name,
       order.payments.first.amount,
       OpenFoodNetwork::UserBalanceCalculator.new(order.user, order.distributor).balance,
       has_temperature_controlled_items?(order),
       order.special_instructions
      ]
    end

    def filter_to_payment_method(search_result)
      if params[:payment_method_in].present?
        search_result.with_payment_method_name(params[:payment_method_in])
      else
        search_result
      end
    end

    def filter_to_shipping_method(search_result)
      if params[:shipping_method_in].present?
        search_result.joins(:shipping_method).where("spree_shipping_methods.name = ?", params[:shipping_method_in])
      else
        search_result
      end
    end

    def has_temperature_controlled_items?(order)
      if order.line_items.any? { |line_item| line_item.product.shipping_category.andand.temperature_controlled }
        "Yes"
      else
        "No"
      end
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
