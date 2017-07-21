module OpenFoodNetwork
  class CustomersReport
    attr_reader :params

    def initialize(user, params = {})
      @params = params
      @user = user
    end

    def header
      if is_mailing_list?
        ["Email", "First Name", "Last Name", "Suburb"]
      else
        ["First Name", "Last Name", "Billing Address", "Email", "Phone", "Hub", "Hub Address", "Shipping Method"]
      end
    end

    def table
      orders.map do |order|
        if is_mailing_list?
          mailing_list_row(order)
        else
          non_mailing_list_row(order)
        end
      end
    end

    def orders
      filter Spree::Order.managed_by(@user).distributed_by_user(@user).complete.not_state(:canceled)
    end

    def filter(orders)
      filter_to_supplier filter_to_distributor filter_to_order_cycle orders
    end

    def filter_to_supplier(orders)
      if params[:supplier_id].to_i > 0
        orders.select do |order|
          order.line_items.includes(:product).where("spree_products.supplier_id = ?", params[:supplier_id].to_i).count > 0
        end
      else
        orders
      end
    end

    def filter_to_distributor(orders)
      if params[:distributor_id].to_i > 0
        orders.where(distributor_id: params[:distributor_id])
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

    private

    def mailing_list_row(order)
      [order.email,
       order.billing_address.firstname,
       order.billing_address.lastname,
       order.billing_address.city]
    end

    def non_mailing_list_row(order)
      billing_address = order.billing_address
      distributor_address = order.distributor.andand.address

      [billing_address.firstname,
       billing_address.lastname,
       [billing_address.address1, billing_address.address2, billing_address.city].join(" "),
       order.email,
       billing_address.phone,
       order.distributor.andand.name,
       [distributor_address.andand.address1, distributor_address.andand.address2, distributor_address.andand.city].join(" "),
       shipping_method_to_display(order).name,
      ]
    end

    def is_mailing_list?
      params[:report_type] == "mailing_list"
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
  end
end
