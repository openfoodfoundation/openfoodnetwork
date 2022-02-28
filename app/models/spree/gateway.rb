# frozen_string_literal: true

require 'concerns/payment_method_distributors'
require 'spree/core/delegate_belongs_to'

module Spree
  class Gateway < PaymentMethod
    acts_as_taggable
    include PaymentMethodDistributors

    delegate_belongs_to :provider, :authorize, :purchase, :capture, :void, :credit

    validates :name, :type, presence: true

    # Default to live
    preference :server, :string, default: 'live'
    preference :test_mode, :boolean, default: false

    def payment_source_class
      CreditCard
    end

    # instantiates the selected gateway and configures with the options stored in the database
    def self.current
      super
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

    def method_missing(method, *args)
      if @provider.nil? || !@provider.respond_to?(method)
        super
      else
        provider.__send__(method, *args)
      end
    end

    def payment_profiles_supported?
      false
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
