# frozen_string_literal: true

class OrderBalance
  delegate :zero?, :abs, :to_s, to: :to_f

  def initialize(order)
    @order = order
  end

  def label
    to_f.negative? ? I18n.t(:credit_owed) : I18n.t(:balance_due)
  end

  def amount
    Spree::Money.new(to_f, currency: order.currency)
  end

  def to_f
    if customer_balance_enabled?
      order.new_outstanding_balance
    else
      order.old_outstanding_balance
    end
  end

  private

  attr_reader :order

  def customer_balance_enabled?
    OpenFoodNetwork::FeatureToggle.enabled?(:customer_balance, order.user)
  end
end
