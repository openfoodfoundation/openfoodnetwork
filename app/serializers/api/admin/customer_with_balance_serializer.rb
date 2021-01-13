# frozen_string_literal: true

module Api
  module Admin
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
