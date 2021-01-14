# frozen_string_literal: true

module Api
  module Admin
    # This serializer relies on `object` to respond to `#balance_value`. That's done in
    # `CustomersWithBalance` due to the fact that ActiveRecord maps the DB result set's columns to
    # instance methods. This way, the `balance_value` alias on that class ends up being
    # `object.balance_value` here.
    class CustomerWithBalanceSerializer < CustomerSerializer
      attributes :balance, :balance_status

      delegate :balance_value, to: :object

      def balance
        Spree::Money.new(balance_value, currency: Spree::Config[:currency]).to_s
      end

      def balance_status
        if balance_value.positive?
          "credit_owed"
        elsif balance_value.negative?
          "balance_due"
        else
          ""
        end
      end
    end
  end
end
