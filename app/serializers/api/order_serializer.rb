class Api::OrderSerializer < ActiveModel::Serializer
  attributes :number, :completed_at, :total, :state, :shipment_state, :payment_state, :outstanding_balance, :payments, :path

  has_many :payments, serializer: Api::PaymentSerializer

  def completed_at
    object.completed_at.blank? ? "" : object.completed_at.to_formatted_s(:long_ordinal)
  end

  def total
    object.total.to_money.to_s
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

  def path
    Spree::Core::Engine.routes_url_helpers.order_url(object.number, only_path: true)
  end
end
