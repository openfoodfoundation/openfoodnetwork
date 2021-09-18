# frozen_string_literal: true

module Checkout
  class GatewayCheckoutSession
    def initialize(payment, success_url, cancel_url)
      @order = payment.order
      @payment = payment
      @success_url = success_url
      @cancel_url = cancel_url
    end

    attr_reader :payment

    def session
      if @order.gateway_checkout_session_id.present?
        checkout_session = Stripe::Checkout::Session.retrieve(@order.gateway_checkout_session_id)
      else
        checkout_session = Stripe::Checkout::Session.create({
          customer_email: @order.user&.email,
          line_items: line_items,
          payment_method_types: [
            'card',
          ],
          mode: 'payment',
          success_url: @success_url,
          cancel_url: @cancel_url
        })
        @order.update_attribute(:gateway_checkout_session_id, checkout_session.id)
      end
      checkout_session
    end

    def save_card
      #TODO
    end

    private

    def line_items
      @order.line_items.map { |li|
        li.attributes.slice("price", "quantity")
        { quantity: li.quantity,
          price_data: {
            currency:  li.currency,
            unit_amount: li.money.cents,
            product_data: {
              name: li.product.name
            }
          }
        }
      }
    end
  end
end
