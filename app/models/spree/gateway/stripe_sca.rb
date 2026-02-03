# frozen_string_literal: true

require 'stripe/profile_storer'
require 'stripe/credit_card_cloner'
require 'stripe/authorize_response_patcher'
require 'stripe/payment_intent_validator'
require 'active_merchant/billing/gateways/stripe'

module Spree
  class Gateway
    class StripeSCA < Gateway
      VOIDABLE_STATES = [
        "requires_payment_method", "requires_capture", "requires_confirmation", "requires_action"
      ].freeze

      preference :enterprise_id, :integer

      validate :ensure_enterprise_selected

      def external_gateway?
        true
      end

      def external_payment_url(options)
        return if options[:order].blank?

        Checkout::StripeRedirect.new(self, options[:order]).path
      end

      def method_type
        'stripe_sca'
      end

      def provider_class
        ActiveMerchant::Billing::StripePaymentIntentsGateway
      end

      def payment_profiles_supported?
        true
      end

      def stripe_account_id
        StripeAccount.find_by(enterprise_id: preferred_enterprise_id)&.stripe_user_id
      end

      # NOTE: this method is required by Spree::Payment::Processing
      def purchase(money, creditcard, gateway_options)
        begin
          payment_intent_id = fetch_payment_intent(creditcard, gateway_options)
        rescue Stripe::StripeError => e
          return failed_activemerchant_billing_response(e.message)
        end

        options = basic_options(gateway_options)
        options[:customer] = creditcard.gateway_customer_profile_id
        provider.capture(money, payment_intent_id, options)
      rescue Stripe::StripeError => e
        failed_activemerchant_billing_response(e.message)
      end

      def capture(money, payment_intent_id, gateway_options)
        options = basic_options(gateway_options)
        provider.capture(money, payment_intent_id, options)
      end

      # NOTE: this method is required by Spree::Payment::Processing
      def charge_offline(money, creditcard, gateway_options)
        customer, payment_method =
          Stripe::CreditCardCloner.new(creditcard, stripe_account_id).find_or_clone

        options = basic_options(gateway_options).merge(customer:, off_session: true)
        provider.purchase(money, payment_method, options)
      rescue Stripe::StripeError => e
        failed_activemerchant_billing_response(e.message)
      end

      # NOTE: this method is required by Spree::Payment::Processing
      def authorize(money, creditcard, gateway_options)
        authorize_response =
          provider.authorize(*options_for_authorize(money, creditcard, gateway_options))
        Stripe::AuthorizeResponsePatcher.new(authorize_response).call!
      rescue Stripe::StripeError => e
        failed_activemerchant_billing_response(e.message)
      end

      # NOTE: this method is required by Spree::Payment::Processing
      def void(payment_intent_id, gateway_options)
        payment_intent_response = Stripe::PaymentIntent.retrieve(
          payment_intent_id, stripe_account: stripe_account_id
        )
        gateway_options[:stripe_account] = stripe_account_id

        # If a payment has been confirmed it can't be voided by Stripe, and must be refunded instead
        if voidable?(payment_intent_response)
          provider.void(payment_intent_id, gateway_options)
        else
          provider.refund(
            payment_intent_response.amount_received, payment_intent_id, gateway_options
          )
        end
      end

      # NOTE: this method is required by Spree::Payment::Processing
      def credit(money, payment_intent_id, gateway_options)
        gateway_options[:stripe_account] = stripe_account_id
        provider.refund(money, payment_intent_id, gateway_options)
      end

      # NOTE: this method is required by Spree::Payment::Processing
      def refund(money, payment_intent_id, gateway_options)
        gateway_options[:stripe_account] = stripe_account_id
        provider.refund(money, payment_intent_id, gateway_options)
      end

      def create_profile(payment)
        return unless payment.source.gateway_customer_profile_id.nil?

        profile_storer = Stripe::ProfileStorer.new(payment, provider)
        profile_storer.create_customer_from_token
      end

      private

      def voidable?(payment_intent_response)
        VOIDABLE_STATES.include? payment_intent_response.status
      end

      # In this gateway, what we call 'secret_key' is the 'login'
      def options
        options = super
        options.merge(login: Stripe.api_key)
      end

      def basic_options(gateway_options)
        options = {}
        options[:description] = "Spree Order ID: #{gateway_options[:order_id]}"
        options[:currency] = gateway_options[:currency]
        options[:stripe_account] = stripe_account_id
        options[:execute_threed] = true # Handle 3DS responses
        options
      end

      def options_for_authorize(money, creditcard, gateway_options)
        options = basic_options(gateway_options)
        options[:return_url] = gateway_options[:return_url] || payment_gateways_confirm_stripe_url

        customer_id, payment_method_id =
          Stripe::CreditCardCloner.new(creditcard, stripe_account_id).find_or_clone
        options[:customer] = customer_id
        [money, payment_method_id, options]
      end

      def fetch_payment_intent(creditcard, gateway_options)
        payment = fetch_payment(creditcard, gateway_options)
        raise Stripe::StripeError, I18n.t(:no_pending_payments) unless payment&.response_code

        payment_intent_response = Stripe::PaymentIntentValidator.new(payment).call

        raise_if_not_in_capture_state(payment_intent_response)

        payment.response_code
      end

      def raise_if_not_in_capture_state(payment_intent_response)
        state = payment_intent_response.status
        return if state == 'requires_capture'

        raise Stripe::StripeError, I18n.t(:invalid_payment_state, state:)
      end

      def fetch_payment(creditcard, gateway_options)
        order_number = gateway_options[:order_id].split('-').first

        Spree::Order.find_by(number: order_number).payments.merge(creditcard.payments).last
      end

      def failed_activemerchant_billing_response(error_message)
        ActiveMerchant::Billing::Response.new(false, error_message)
      end

      def ensure_enterprise_selected
        return if preferred_enterprise_id&.positive?

        errors.add(:stripe_account_owner, I18n.t(:error_required))
      end
    end
  end
end
