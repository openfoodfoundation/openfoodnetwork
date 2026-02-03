# frozen_string_literal: true

module Spree
  class PaymentMethod < ApplicationRecord
    include CalculatedAdjustments
    include PaymentMethodDistributors

    self.belongs_to_required_by_default = false

    acts_as_taggable
    acts_as_paranoid

    DISPLAY = [:both, :back_end].freeze
    default_scope -> { where(deleted_at: nil) }

    has_many :credit_cards, class_name: "Spree::CreditCard", dependent: :destroy

    validates :name, presence: true
    validate :distributor_validation
    validates_associated :calculator

    after_initialize :init

    scope :inactive_or_backend, -> { where("active = false OR display_on = 'back_end'") }

    scope :production, -> { where(environment: 'production') }

    scope :managed_by, lambda { |user|
      return where(nil) if user.admin?

      joins(:distributors).
        where(distributors_payment_methods: { distributor_id: user.enterprises.select(&:id) }).
        select('DISTINCT spree_payment_methods.*')
    }

    scope :for_distributors, ->(distributors) {
      non_unique_matches = unscoped.joins(:distributors).where(enterprises: { id: distributors })
      where(id: non_unique_matches.map(&:id))
    }

    scope :for_distributor, ->(distributor) {
      joins(:distributors).where(enterprises: { id: distributor })
    }

    scope :for_subscriptions, -> { where(type: Subscription::ALLOWED_PAYMENT_METHOD_TYPES) }

    scope :by_name, -> { order('spree_payment_methods.name ASC') }

    scope :available, lambda { |display_on = 'both'|
      where(active: true)
        .where(display_on: [display_on, "", nil])
        .where(environment: [Rails.env, "", nil])
    }

    def configured?
      !stripe? || stripe_configured?
    end

    def provider_class
      raise 'You must implement provider_class method for this gateway.'
    end

    # Does the PaymentMethod require redirecting to an external gateway?
    def external_gateway?
      false
    end

    # Inheriting PaymentMethods can implement this method if needed
    def external_payment_url(_options)
      nil
    end

    def frontend?
      active? && display_on != "back_end"
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

    def self.find_with_destroyed(*)
      unscoped { find(*) }
    end

    def source_required?
      true
    end

    def supports?(_source)
      true
    end

    def init
      self.calculator ||= ::Calculator::None.new
    end

    def has_distributor?(distributor)
      distributors.include?(distributor)
    end

    def self.clean_name
      scope = "spree.admin.payment_methods.providers"
      I18n.t(name.demodulize.downcase, scope:)
    end

    private

    def distributor_validation
      validates_with DistributorsValidator
    end

    def stripe?
      type.ends_with?("StripeSCA")
    end

    def stripe_configured?
      Spree::Config.stripe_connect_enabled &&
        Stripe.publishable_key &&
        preferred_enterprise_id.present? &&
        preferred_enterprise_id > 0 &&
        stripe_account_id.present?
    end
  end
end
