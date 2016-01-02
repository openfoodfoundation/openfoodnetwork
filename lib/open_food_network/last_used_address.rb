module OpenFoodNetwork
  class LastUsedAddress
    def initialize(email)
      @email = email
    end

    def last_used_bill_address
      recent_orders.detect(&:bill_address).andand.bill_address
    end

    def last_used_ship_address
      recent_orders.detect do |o|
        o.ship_address && o.shipping_method.andand.require_ship_address
      end.andand.ship_address
    end

    private

    def recent_orders
      Spree::Order
        .order('id DESC')
        .where(email: @email)
        .where("state != 'cart'")
        .limit(8)
    end
  end
end
