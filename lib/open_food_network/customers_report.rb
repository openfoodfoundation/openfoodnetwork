module OpenFoodNetwork
  class CustomersReport
    attr_reader :params
    def initialize(user, params = {})
      @params = params
      @user = user
    end

    def header
      if is_mailing_list?
        [I18n.t(:report_header_email),
          I18n.t(:report_header_first_name),
          I18n.t(:report_header_last_name),
          I18n.t(:report_header_suburb)]
      else
        [I18n.t(:report_header_first_name),
          I18n.t(:report_header_last_name),
          I18n.t(:report_header_billing_address),
          I18n.t(:report_header_email),
          I18n.t(:report_header_phone),
          I18n.t(:report_header_hub),
          I18n.t(:report_header_hub_address),
          I18n.t(:report_header_shipping_method)]
      end
    end

    def table
      orders.map do |order|
        if is_mailing_list?
          [order.email,
           order.billing_address.firstname,
           order.billing_address.lastname,
           order.billing_address.city]
        else
          ba = order.billing_address
          da = order.distributor.andand.address
          [ba.firstname,
            ba.lastname,
            [ba.address1, ba.address2, ba.city].join(" "),
            order.email,
            ba.phone,
            order.distributor.andand.name,
            [da.andand.address1, da.andand.address2, da.andand.city].join(" "),
            order.shipping_method.andand.name
          ]
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

    def is_mailing_list?
      params[:report_type] == "mailing_list"
    end
  end
end
