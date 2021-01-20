# frozen_string_literal: true

# Fetches complete orders of the specified user including their balance as a computed column
class CompleteOrdersWithBalance
  def initialize(user)
    @user = user
  end

  def query
    OutstandingBalance.new(sorted_finalized_orders).query
  end

  private

  def sorted_finalized_orders
    @user.orders
      .finalized
      .select('spree_orders.*')
      .order(completed_at: :desc)
  end
end
