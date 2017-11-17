module OpenFoodNetwork
  class StandingOrderPaymentUpdater
    def initialize(order)
      @order = order
    end

    def update!
      create_payment if payment.blank?

      if card_required? && !card_set?
        return unless ensure_credit_card
      end

      payment.update_attributes(amount: @order.outstanding_balance)
    end

    private

    def payment
      @payment ||= @order.pending_payments.last
    end

    def create_payment
      @payment = @order.payments.create(
        payment_method_id: @order.standing_order.payment_method_id,
        amount: @order.outstanding_balance
      )
    end

    def card_required?
      payment.payment_method.is_a? Spree::Gateway::StripeConnect
    end

    def card_set?
      payment.source is_a? Spree::CreditCard
    end

    def ensure_credit_card
      return false unless saved_credit_card.present?
      payment.update_attributes(source: saved_credit_card)
    end

    def saved_credit_card
      @order.standing_order.credit_card
    end
  end
end
