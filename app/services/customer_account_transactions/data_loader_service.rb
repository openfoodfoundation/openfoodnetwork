# frozen_string_literal: false

module CustomerAccountTransactions
  class DataLoaderService
    attr_reader :user, :enterprise

    def initialize(user:, enterprise:)
      @user = user
      @enterprise = enterprise
    end

    def customer_account_transactions
      return [] if user.customers.empty?

      enterprise_customer = user.customers.find_by(enterprise: )
      return [] if enterprise_customer.nil?

      enterprise_customer.customer_account_transactions.order(id: :desc)
    end

    def available_credit
      return 0 if customer_account_transactions.empty?

      # We are ordered by newest, so the lastest transaction is the first one
      customer_account_transactions.first.balance
    end
  end
end
