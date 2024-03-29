# frozen_string_literal: true

# Fetches complete orders of the specified user including their balance as a computed column
class CompleteOrdersWithBalanceQuery
  def initialize(user)
    @user = user
  end

  def call
    OutstandingBalanceQuery.new(sorted_finalized_orders).call
  end

  private

  def sorted_finalized_orders
    @user.orders
      .finalized
      .select('spree_orders.*')
      .order(completed_at: :desc)
  end
end
