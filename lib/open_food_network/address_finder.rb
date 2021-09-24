# frozen_string_literal: true

# Finds an address based on the data provided
# Can take any combination of an email String, Customer or Spree::User as args
# The #bill_address and #ship_address methods automatically return matched addresses
# according to this order: customer addresses, user addresses, addresses from
# completed orders with an email that matches the email string provided.

module OpenFoodNetwork
  class AddressFinder
    attr_reader :email, :user, :customer

    def initialize(*args)
      args.each do |arg|
        type = types[arg.class]
        next unless type

        public_send("#{type}=", arg)
      end
    end

    def bill_address
      customer_preferred_bill_address || user_preferred_bill_address || fallback_bill_address
    end

    def ship_address
      customer_preferred_ship_address || user_preferred_ship_address || fallback_ship_address
    end

    def email=(arg)
      @email ||= arg
    end

    def customer=(arg)
      @customer ||= arg
    end

    def user=(arg)
      @user ||= arg
    end

    private

    def types
      {
        String => "email",
        Customer => "customer",
        Spree::User => "user"
      }
    end

    def customer_preferred_bill_address
      customer&.bill_address
    end

    def customer_preferred_ship_address
      customer&.ship_address
    end

    def user_preferred_bill_address
      user&.bill_address
    end

    def user_preferred_ship_address
      user&.ship_address
    end

    def fallback_bill_address
      last_used_bill_address&.clone
    end

    def fallback_ship_address
      last_used_ship_address&.clone
    end

    def last_used_bill_address
      return nil unless allow_search_by_email?

      Spree::Order.joins(:bill_address).order('id DESC')
        .complete.where(email: email)
        .first&.bill_address
    end

    def last_used_ship_address
      return nil unless allow_search_by_email?

      Spree::Order.complete.joins(:ship_address, shipments: :shipping_methods).order('id DESC')
        .where(email: email, spree_shipping_methods: { require_ship_address: true })
        .first&.ship_address
    end

    # Only allow search for address by email if a customer or user with the
    # same address has been provided, otherwise we are providing access to
    # addresses with only an email address, which could be problematic.
    # Assumption: front-end users can't ask this library for an address using
    # a customer or user other than themselves...
    def allow_search_by_email?
      email.present? && email_matches_customer_or_user?
    end

    def email_matches_customer_or_user?
      email == customer&.email || email == user&.email
    end
  end
end
