# Returns the capturable payment object for an order with balance due

class PendingPayments
  def initialize(order)
    @order = order
  end

  def payment_object
    @order.payments.select{ |payment| payment if payment.state == 'checkout' }.first
  end

  def can_be_captured?
    payment_object && payment_object.actions.include?('capture')
  end
end
