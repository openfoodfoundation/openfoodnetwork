# frozen_string_literal: true

module Spree
  class PaymentMethod < ActiveRecord::Base
    include Spree::Core::CalculatedAdjustments
    include PaymentMethodDistributors

    acts_as_taggable
    acts_as_paranoid

    DISPLAY = [:both, :front_end, :back_end].freeze
    default_scope -> { where(deleted_at: nil) }

    has_many :credit_cards, class_name: "Spree::CreditCard"

    validates :name, presence: true
    validate :distributor_validation

    after_initialize :init

    scope :production, -> { where(environment: 'production') }

    scope :managed_by, lambda { |user|
      if user.has_spree_role?('admin')
        where(nil)
      else
        joins(:distributors).
          where('distributors_payment_methods.distributor_id IN (?)',
                user.enterprises.select(&:id)).
          select('DISTINCT spree_payment_methods.*')
      end
    }

    scope :for_distributors, ->(distributors) {
      non_unique_matches = unscoped.joins(:distributors).where(enterprises: { id: distributors })
      where(id: non_unique_matches.map(&:id))
    }

    scope :for_distributor, lambda { |distributor|
      joins(:distributors).
        where('enterprises.id = ?', distributor)
    }

    scope :for_subscriptions, -> { where(type: Subscription::ALLOWED_PAYMENT_METHOD_TYPES) }

    scope :by_name, -> { order('spree_payment_methods.name ASC') }

    scope :available, lambda { |display_on = 'both'|
      where(active: true).
        where('spree_payment_methods.display_on=? OR spree_payment_methods.display_on=? OR spree_payment_methods.display_on IS NULL', display_on, '').
        where('spree_payment_methods.environment=? OR spree_payment_methods.environment=? OR spree_payment_methods.environment IS NULL', Rails.env, '')
    }

    def self.providers
      Rails.application.config.spree.payment_methods
    end

    def provider_class
      raise 'You must implement provider_class method for this gateway.'
    end

    # The class that will process payments for this payment type, used for @payment.source
    # e.g. CreditCard in the case of a the Gateway payment type
    # nil means the payment method doesn't require a source e.g. check
    def payment_source_class
      raise 'You must implement payment_source_class method for this gateway.'
    end

    def self.active?
      where(type: to_s, environment: Rails.env, active: true).count.positive?
    end

    def method_type
      type.demodulize.downcase
    end

    def self.find_with_destroyed(*args)
      unscoped { find(*args) }
    end

    def payment_profiles_supported?
      false
    end

    def source_required?
      true
    end

    def auto_capture?
      Spree::Config[:auto_capture]
    end

    def supports?(_source)
      true
    end

    def init
      unless _reflections.key?(:calculator)
        self.class.include Spree::Core::CalculatedAdjustments
      end

      self.calculator ||= Calculator::FlatRate.new(preferred_amount: 0)
    end

    def has_distributor?(distributor)
      distributors.include?(distributor)
    end

    def self.clean_name
      case name
      when "Spree::PaymentMethod::Check"
        "Cash/EFT/etc. (payments for which automatic validation is not required)"
      when "Spree::Gateway::Migs"
        "MasterCard Internet Gateway Service (MIGS)"
      when "Spree::Gateway::Pin"
        "Pin Payments"
      when "Spree::Gateway::StripeConnect"
        "Stripe"
      when "Spree::Gateway::StripeSCA"
        "Stripe SCA"
      when "Spree::Gateway::PayPalExpress"
        "PayPal Express"
      else
        i = name.rindex('::') + 2
        name[i..-1]
      end
    end

    private

    def distributor_validation
      validates_with DistributorsValidator
    end
  end
end
