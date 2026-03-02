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
