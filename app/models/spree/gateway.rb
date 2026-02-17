# frozen_string_literal: true

module Spree
  class Gateway < PaymentMethod
    acts_as_taggable
    include PaymentMethodDistributors

    delegate :authorize, :purchase, :capture, :void, :credit, :refund, to: :provider

    validates :name, :type, presence: true

    # Default to live
    preference :server, :string, default: 'live'
    preference :test_mode, :boolean, default: false

    def actions
      %w{capture_and_complete_order void credit resend_authorization_email}
    end

    # Indicates whether its possible to capture the payment
    def can_capture_and_complete_order?(payment)
      return false if payment.requires_authorization?

      payment.pending? || payment.checkout?
    end

    # Indicates whether its possible to void the payment.
    def can_void?(payment)
      !payment.void?
    end

    # Indicates whether its possible to credit the payment. Note that most gateways require that the
    #   payment be settled first which generally happens within 12-24 hours of the transaction.
    def can_credit?(payment)
      return false unless payment.completed?
      return false unless payment.order.payment_state == 'credit_owed'

      payment.credit_allowed.positive?
    end

    def can_resend_authorization_email?(payment)
      payment.requires_authorization?
    end

    def payment_source_class
      CreditCard
    end

    def provider
      gateway_options = options
      gateway_options.delete :login if gateway_options.key?(:login) && gateway_options[:login].nil?
      if gateway_options[:server]
        ActiveMerchant::Billing::Base.mode = gateway_options[:server].to_sym
      end
      @provider ||= provider_class.new(gateway_options)
    end

    def options
      preferences.transform_keys(&:to_sym)
    end

    def respond_to_missing?(method_name, include_private = false)
      @provider.respond_to?(method_name, include_private) || super
    end

    def method_missing(method, *)
      message = "Deprecated delegation of Gateway##{method}"
      Alert.raise(message)
      raise message if Rails.env.local?

      if @provider.nil? || !@provider.respond_to?(method)
        super
      else
        provider.__send__(method, *)
      end
    end

    def method_type
      'gateway'
    end

    def supports?(source)
      return true unless provider_class.respond_to? :supports?
      return false unless source.brand

      provider_class.supports?(source.brand)
    end
  end
end
