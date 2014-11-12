module OpenFoodNetwork
  class OrderCycleManagementReport
    attr_reader :params
    def initialize(user, params = {})
      @params = params
      @user = user
    end

    def header
      ["First Name", "Last Name", "Email", "Phone", "Hub", "Shipping Method", "Payment Method", "Amount ", "Amount Paid"]
    
    end

    def table
      orders.map do |order|
        ba = order.billing_address
        da = order.distributor.andand.address
        [ba.firstname,
          ba.lastname,
          order.email,
           ba.phone,
           order.distributor.andand.name,
           order.shipping_method.andand.name,
           order.payments.first.andand.payment_method.andand.name,
	   order.payments.first.amount
        ]       
      end
    end

    def orders
      filter Spree::Order
    end

    def filter(orders)
      filter_for_user filter_active filter_to_order_cycle filter_to_payment_method filter_to_distribution orders
    end
  
    def filter_for_user (orders)
       orders.managed_by(@user).distributed_by_user(@user)
    end	

    def filter_active (orders)
       orders.complete.where("spree_orders.state != ?", :cancelled)
    end

    def filter_to_payment_method (orders)
      if params.has_key? (:payment_method_name)
        orders.with_payment_method_name(params[:payment_method_name])
      else
        orders
      end
    end

    def filter_to_distribution (orders)
      if params.has_key? (:distribution_name)
        orders.joins(:shipping_method).where("spree_shipping_methods.name = ?", params[:distribution_name])
      else
        orders
      end
    end

    def filter_to_order_cycle(orders)
      if params[:order_cycle_id].to_i > 0
        orders.where(order_cycle_id: params[:order_cycle_id])
      else
        orders
      end
    end

  
  end
end

