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
          [order.email,
           order.billing_address.firstname,
           order.billing_address.lastname,
           order.billing_address.city]
        else
          ba = order.billing_address
          da = order.distributor.address
          [ba.firstname,
            ba.lastname,
            [ba.address1, ba.address2, ba.city].join(" "),
            order.email,
            ba.phone,
            order.distributor.name,
            [da.address1, da.address2, da.city].join(" "),
            order.shipping_method.name 
          ]
        end
      end
    end

    def orders
      Spree::Order.managed_by(@user).complete.not_state(:canceled)
    end

    private

    def is_mailing_list?
      params[:report_type] == "mailing_list"
    end
  end
end

