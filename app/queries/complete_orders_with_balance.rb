# frozen_string_literal: true

# Fetches complete orders of the specified user including their balance as a computed column
class CompleteOrdersWithBalance
  def initialize(user)
    @user = user
  end

  def query
    OutstandingBalance.new(sorted_complete_orders).query
  end

  private

  def sorted_complete_orders
    @user.orders
      .where.not(Spree::Order.in_incomplete_state.where_values_hash)
      .select('spree_orders.*')
      .order(completed_at: :desc)
  end
end
