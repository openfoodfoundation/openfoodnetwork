# frozen_string_literal: true

class OrderBalance
  delegate :zero?, :abs, :to_s, :to_f, :to_d, :<, :>, to: :amount

  def initialize(order)
    @order = order
  end

  def label
    amount.negative? ? I18n.t(:credit_owed) : I18n.t(:balance_due)
  end

  def display_amount
    Spree::Money.new(amount, currency: order.currency)
  end

  def amount
    order.new_outstanding_balance
  end

  def +(other)
    amount + other.to_f
  end

  private

  attr_reader :order
end
