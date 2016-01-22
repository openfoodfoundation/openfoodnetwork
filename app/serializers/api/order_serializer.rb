class Api::OrderSerializer < ActiveModel::Serializer
  attributes :number, :completed_at, :total, :state, :shipment_state, :payment_state, :outstanding_balance, :total_money, :balance_money, :payments, :path

  has_many :payments, serializer: Api::PaymentSerializer

  def completed_at
    object.completed_at.blank? ? "" : object.completed_at.to_formatted_s(:long_ordinal)
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

  def path
    spree.order_url(object.number, only_path: true)
  end

  private

  def to_money(amount)
    {currency_symbol:amount.to_money.currency_symbol, amount:amount.to_money.to_s}
  end
end
