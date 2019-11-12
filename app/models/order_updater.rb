require 'delegate'

class OrderUpdater < SimpleDelegator
  # TODO: This logic adapted from Spree 2.4, remove when we get there
  # Handles state updating in a much more logical way than < 2.4
  # Specifically, doesn't depend on payments.last to determine payment state
  # Also swapped: == 0 for .zero?, .size == 0 for empty? and .size > 0 for !empty?
  # See:
  # https://github.com/spree/spree/commit/38b8456183d11fc1e00e395e7c9154c76ef65b85
  # https://github.com/spree/spree/commit/7b264acff7824f5b3dc6651c106631d8f30b147a
  def update_payment_state
    last_payment_state = order.payment_state

    order.payment_state = infer_payment_state
    track_payment_state_change(last_payment_state)

    order.payment_state
  end

  def before_save_hook
    shipping_address_from_distributor
  end

  # Sets the distributor's address as shipping address of the order for those
  # shipments using a shipping method that doesn't require address, such us
  # a pickup.
  def shipping_address_from_distributor
    return if order.shipping_method.blank? || order.shipping_method.require_ship_address

    order.ship_address = order.address_from_distributor
  end

  private

  def infer_payment_state
    if failed_payments?
      'failed'
    elsif canceled_and_not_paid_for?
      'void'
    else
      infer_payment_state_from_balance
    end
  end

  def infer_payment_state_from_balance
    # This part added so that we don't need to override
    # order.outstanding_balance
    balance = order.outstanding_balance
    balance = -1 * order.payment_total if canceled_and_paid_for?

    infer_state(balance)
  end

  def infer_state(balance)
    if balance > 0
      'balance_due'
    elsif balance < 0
      'credit_owed'
    elsif balance.zero?
      'paid'
    end
  end

  # Tracks the state transition through a state_change for this order. It
  # does so until the last state is reached. That is, when the infered next
  # state is the same as the order has now.
  #
  # @param last_payment_state [String]
  def track_payment_state_change(last_payment_state)
    return if last_payment_state == order.payment_state

    order.state_changed('payment')
  end

  # Taken from order.outstanding_balance in Spree 2.4
  # See: https://github.com/spree/spree/commit/7b264acff7824f5b3dc6651c106631d8f30b147a
  def canceled_and_paid_for?
    order.canceled? && paid?
  end

  def canceled_and_not_paid_for?
    order.state == 'canceled' && order.payment_total.zero?
  end

  def paid?
    payments.present? && !payments.completed.empty?
  end

  def failed_payments?
    payments.present? && payments.valid.empty?
  end
end
