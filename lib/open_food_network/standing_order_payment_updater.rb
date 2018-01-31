module OpenFoodNetwork
  class StandingOrderPaymentUpdater
    def initialize(order)
      @order = order
    end

    def update!
      create_payment
      ensure_payment_source
      return if order.errors.any?

      payment.update_attributes(amount: order.outstanding_balance)
    end

    private

    attr_reader :order

    def payment
      @payment ||= order.pending_payments.last
    end

    def create_payment
      return if payment.present?
      @payment = order.payments.create(
        payment_method_id: order.standing_order.payment_method_id,
        amount: order.outstanding_balance
      )
    end

    def card_required?
      payment.payment_method.is_a? Spree::Gateway::StripeConnect
    end

    def card_set?
      payment.source is_a? Spree::CreditCard
    end

    def ensure_payment_source
      return unless card_required? && !card_set?
      ensure_credit_card || order.errors.add(:base, :no_card)
    end

    def ensure_credit_card
      return false if saved_credit_card.blank?
      payment.update_attributes(source: saved_credit_card)
    end

    def saved_credit_card
      order.standing_order.credit_card
    end

    def errors_present?
      order.errors.any?
    end
  end
end
