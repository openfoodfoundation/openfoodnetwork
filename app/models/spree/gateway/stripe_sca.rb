# frozen_string_literal: true

require 'stripe/profile_storer'
require 'stripe/credit_card_cloner'
require 'stripe/authorize_response_patcher'
require 'stripe/payment_intent_validator'
require 'active_merchant/billing/gateways/stripe_payment_intents'
require 'active_merchant/billing/gateways/stripe_decorator'

module Spree
  class Gateway
    class StripeSCA < Gateway
      preference :enterprise_id, :integer

      validate :ensure_enterprise_selected

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
        StripeAccount.find_by(enterprise_id: preferred_enterprise_id).andand.stripe_user_id
      end

      # NOTE: the name of this method is determined by Spree::Payment::Processing
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

      # NOTE: the name of this method is determined by Spree::Payment::Processing
      def authorize(money, creditcard, gateway_options)
        authorize_response = provider.authorize(*options_for_authorize(money,
                                                                       creditcard,
                                                                       gateway_options))
        Stripe::AuthorizeResponsePatcher.new(authorize_response).call!
      rescue Stripe::StripeError => e
        failed_activemerchant_billing_response(e.message)
      end

      # NOTE: the name of this method is determined by Spree::Payment::Processing
      def void(response_code, _creditcard, gateway_options)
        payment_intent_id = response_code
        payment_intent_response = Stripe::PaymentIntent.retrieve(payment_intent_id,
                                                                 stripe_account: stripe_account_id)
        gateway_options[:stripe_account] = stripe_account_id
        provider.refund(payment_intent_response.amount_received, response_code, gateway_options)
      end

      # NOTE: the name of this method is determined by Spree::Payment::Processing
      def credit(money, _creditcard, response_code, gateway_options)
        gateway_options[:stripe_account] = stripe_account_id
        provider.refund(money, response_code, gateway_options)
      end

      def create_profile(payment)
        return unless payment.source.gateway_customer_profile_id.nil?

        profile_storer = Stripe::ProfileStorer.new(payment, provider)
        profile_storer.create_customer_from_token
      end

      private

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
        options
      end

      def options_for_authorize(money, creditcard, gateway_options)
        options = basic_options(gateway_options)
        options[:return_url] = full_checkout_path

        customer_id, payment_method_id = Stripe::CreditCardCloner.new.clone(creditcard,
                                                                            stripe_account_id)
        options[:customer] = customer_id
        [money, payment_method_id, options]
      end

      def fetch_payment_intent(creditcard, gateway_options)
        payment = fetch_payment(creditcard, gateway_options)
        raise Stripe::StripeError, I18n.t(:no_pending_payments) unless payment&.response_code

        Stripe::PaymentIntentValidator.new.call(payment.response_code, stripe_account_id)
      end

      def fetch_payment(creditcard, gateway_options)
        order_number = gateway_options[:order_id].split('-').first

        Spree::Order.find_by(number: order_number).payments.merge(creditcard.payments).last
      end

      def failed_activemerchant_billing_response(error_message)
        ActiveMerchant::Billing::Response.new(false, error_message)
      end

      def ensure_enterprise_selected
        return if preferred_enterprise_id.andand.positive?

        errors.add(:stripe_account_owner, I18n.t(:error_required))
      end

      def full_checkout_path
        URI.join(url_helpers.root_url, url_helpers.checkout_path).to_s
      end

      def url_helpers
        # This is how we can get the helpers with a usable root_url outside the controllers
        Rails.application.routes.default_url_options = ActionMailer::Base.default_url_options
        Rails.application.routes.url_helpers
      end
    end
  end
end
