# frozen_string_literal: true

module Api
  module Admin
    class CustomerWithCalculatedBalanceSerializer < CustomerSerializer
      attributes :balance, :balance_status

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

      def balance_value
        @balance_value ||=
          OpenFoodNetwork::UserBalanceCalculator.new(object.email, object.enterprise).balance
      end
    end
  end
end
