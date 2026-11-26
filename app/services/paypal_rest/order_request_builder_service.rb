# frozen_string_literal: true

module PaypalRest
  class OrderRequestBuilderService
    def initialize(order:, payment:, payment_method:, return_url:, cancel_url:)
      @order = order
      @payment = payment
      @payment_method = payment_method
      @return_url = return_url
      @cancel_url = cancel_url
    end

    def call
      PaypalServerSdk::OrderRequest.new(
        intent: PaypalServerSdk::CheckoutPaymentIntent::CAPTURE,
        purchase_units: [purchase_unit],
        payment_source: {
          paypal: {
            experience_context: {
              return_url: return_url,
              cancel_url: cancel_url,
              user_action: PaypalServerSdk::PaypalExperienceUserAction::PAY_NOW,
              shipping_preference: shipping_preference
            }
          }
        }
      )
    end

    private

    attr_reader :order, :payment, :payment_method, :return_url, :cancel_url

    def purchase_unit
      PurchaseUnitBuilderService.new(
        order: order,
        payment: payment,
        address_required: address_required?
      ).call
    end

    def shipping_preference
      return PaypalServerSdk::PaypalWalletContextShippingPreference::NO_SHIPPING unless
        address_required?

      if order.ship_address.present?
        PaypalServerSdk::PaypalWalletContextShippingPreference::SET_PROVIDED_ADDRESS
      else
        PaypalServerSdk::PaypalWalletContextShippingPreference::GET_FROM_FILE
      end
    end

    def address_required?
      payment_method.respond_to?(:preferred_solution) &&
        payment_method.preferred_solution.to_s == "Sole"
    end
  end
end
