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
  def new_outstanding_balance
    if state.in?(FINALIZED_NON_SUCCESSFUL_STATES)
      -payment_total
    else
      total - payment_total
    end
  end

  # This method is the one we're gradually replacing with `#new_outstanding_balance`. Having them
  # separate enables us to choose which implementation we want depending on the context using
  # a feature toggle. This avoids incosistent behavior across the app during that incremental
  # refactoring.
  #
  # It is meant to be removed as soon as we get product approval that the new implementation has
  # been working correctly in production.
  def outstanding_balance
    total - payment_total
  end

  def outstanding_balance?
    !outstanding_balance.zero?
  end

  def display_outstanding_balance
    Spree::Money.new(outstanding_balance, currency: currency)
  end
end
