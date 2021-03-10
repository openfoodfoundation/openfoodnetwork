# frozen_string_literal: true

class OrderBalance
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
      order.outstanding_balance
    end
  end

  delegate :zero?, to: :to_f

  private

  attr_reader :order

  def customer_balance_enabled?
    OpenFoodNetwork::FeatureToggle.enabled?(:customer_balance, order.user)
  end
end
