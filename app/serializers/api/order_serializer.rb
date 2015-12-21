class Api::OrderSerializer < ActiveModel::Serializer
  attributes :id, :completed_at, :total, :state, :shipment_state, :payment_state, :outstanding_balance, :total_money, :balance_money

  def completed_at
    object.completed_at.blank? ? "" : object.completed_at.strftime("%F %T")
  end

  def total_money
    to_money(object.total)
  end

  def shipment_state
    object.shipment_state ? object.shipment_state.humanize : nil # Or a call to t() here?
  end

  def payment_state
    object.payment_state ? object.payment_state.humanize : nil # Or a call to t() here?
  end

  def state
    object.state ? object.state.humanize : nil # Or a call to t() here?
  end

  def balance_money
    to_money(object.outstanding_balance)
  end

  private

  def to_money(amount)
    {currency_symbol:amount.to_money.currency_symbol, amount:amount.to_money.to_s}
  end
end
