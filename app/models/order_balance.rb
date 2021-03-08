# frozen_string_literal: true

class OrderBalance
  def initialize(order)
    @order = order
  end

  def state
    outstanding_balance.negative? ? I18n.t(:credit_owed) : I18n.t(:balance_due)
  end

  def amount
    Spree::Money.new(outstanding_balance, currency: order.currency)
  end

  private

  attr_reader :order

  def outstanding_balance
    if OpenFoodNetwork::FeatureToggle.enabled?(:customer_balance, order.user)
      order.new_outstanding_balance
    else
      order.outstanding_balance
    end
  end
end
