# Finds an address based on the data provided
# Can take any combination of an email String, Customer or Spree::User as args
# The #bill_address and #ship_address methods automatically return matched addresses
# according to this order: customer addresses, user addresses, addresses from
# completed orders with an email that matches the email string provided.
module OpenFoodNetwork
  class AddressFinder
    attr_accessor :email, :user, :customer

    def initialize(*args)
      args.each do |arg|
        case arg
        when String
          @email = arg unless @email
        when Customer
          @customer = arg unless @customer
        when Spree::User
          @user = arg unless @user
        end
      end
    end

    def bill_address
      customer_preferred_bill_address || user_preferred_bill_address || fallback_bill_address
    end

    def ship_address
      customer_preferred_ship_address || user_preferred_ship_address || fallback_ship_address
    end

    private

    def customer_preferred_bill_address
      customer.andand.bill_address
    end

    def customer_preferred_ship_address
      customer.andand.ship_address
    end

    def user_preferred_bill_address
      user.andand.bill_address
    end

    def user_preferred_ship_address
      user.andand.ship_address
    end

    def fallback_bill_address
      last_used_bill_address.andand.clone || Spree::Address.default
    end

    def fallback_ship_address
      last_used_ship_address.andand.clone || Spree::Address.default
    end

    def last_used_bill_address
      return nil unless email
      Spree::Order.joins(:bill_address).order('id DESC')
      .complete.where(email: email)
      .first.andand.bill_address
    end

    def last_used_ship_address
      return nil unless email
      Spree::Order.complete.joins(:ship_address, :shipping_method).order('id DESC')
      .where(email: email, spree_shipping_methods: { require_ship_address: true })
      .first.andand.ship_address
    end
  end
end
