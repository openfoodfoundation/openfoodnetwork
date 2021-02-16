# frozen_string_literal: true

require 'active_support/concern'

# Contains the methods to compute an order balance form the point of view of the enterprise and not
# the individual shopper.
module Balance
  FINALIZED_NON_SUCCESSFUL_STATES = %w(canceled returned).freeze

  # Returns the order balance by considering the total as money owed to the order distributor aka.
  # the shop, and as a positive balance of said enterprise. If the customer pays it all, they
  # distributor and customer are even.
  #
  # Note however, this is meant to be used only in the context of a single order object. When
  # working with a collection of orders, such an index controller action, please consider using
  # `app/queries/oustanding_balance.rb` instead so we avoid potential N+1s.
  def outstanding_balance
    if state.in?(FINALIZED_NON_SUCCESSFUL_STATES)
      -payment_total
    else
      total - payment_total
    end
  end

  def outstanding_balance?
    !outstanding_balance.zero?
  end

  def display_outstanding_balance
    Spree::Money.new(outstanding_balance, currency: currency)
  end
end
