# frozen_string_literal: true

require 'stripe/profile_storer'
require 'active_merchant/billing/gateways/stripe_payment_intents'
require 'active_merchant/billing/gateways/stripe_decorator'

module Spree
  class Gateway
    class StripeSCA < Gateway
      preference :enterprise_id, :integer

      validate :ensure_enterprise_selected

      attr_accessible :preferred_enterprise_id

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
        StripeAccount.find_by_enterprise_id(preferred_enterprise_id).andand.stripe_user_id
      end

      # NOTE: the name of this method is determined by Spree::Payment::Processing
      def purchase(money, creditcard, gateway_options)
        provider.purchase(*options_for_purchase_or_auth(money, creditcard, gateway_options))
      rescue Stripe::StripeError => e
        # This will be an error caused by generating a stripe token
        failed_activemerchant_billing_response(e.message)
      end

      # NOTE: the name of this method is determined by Spree::Payment::Processing
      def void(response_code, _creditcard, gateway_options)
        gateway_options[:stripe_account] = stripe_account_id
        provider.void(response_code, gateway_options)
      end

      # NOTE: the name of this method is determined by Spree::Payment::Processing
      def credit(money, _creditcard, response_code, gateway_options)
        gateway_options[:stripe_account] = stripe_account_id
        provider.refund(money, response_code, gateway_options)
      end

      def create_profile(payment)
        return unless payment.source.gateway_customer_profile_id.nil?

        profile_storer = Stripe::ProfileStorer.new(payment, provider, stripe_account_id)
        profile_storer.create_customer_from_token
      end

      private

      # In this gateway, what we call 'secret_key' is the 'login'
      def options
        options = super
        options.merge(login: Stripe.api_key)
      end

      def options_for_purchase_or_auth(money, creditcard, gateway_options)
        options = {}
        options[:description] = "Spree Order ID: #{gateway_options[:order_id]}"
        options[:currency] = gateway_options[:currency]
        options[:stripe_account] = stripe_account_id

        convert_to_payment_method!(creditcard) if creditcard.gateway_payment_profile_id.starts_with?('card_')

        options[:customer] = creditcard.gateway_customer_profile_id
        payment_method = creditcard.gateway_payment_profile_id

        [money, payment_method, options]
      end

      def convert_to_payment_method!(creditcard)
        card_id = creditcard.gateway_payment_profile_id
        customer_id = creditcard.gateway_customer_profile_id
        new_payment_method = Stripe::PaymentMethod.create({ customer: customer_id, payment_method: card_id }, { stripe_account: stripe_account_id })

        new_customer = Stripe::Customer.create({ email: creditcard.user.email }, { stripe_account: stripe_account_id })
        Stripe::PaymentMethod.attach(new_payment_method.id, { customer: new_customer.id }, { stripe_account: stripe_account_id })

        creditcard.update_attributes gateway_customer_profile_id: new_customer.id, gateway_payment_profile_id: new_payment_method.id
        creditcard
      end

      def failed_activemerchant_billing_response(error_message)
        ActiveMerchant::Billing::Response.new(false, error_message)
      end

      def ensure_enterprise_selected
        return if preferred_enterprise_id.andand.positive?

        errors.add(:stripe_account_owner, I18n.t(:error_required))
      end
    end
  end
end
