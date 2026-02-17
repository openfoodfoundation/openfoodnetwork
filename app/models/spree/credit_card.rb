# frozen_string_literal: true

module Spree
  class CreditCard < ApplicationRecord
    self.belongs_to_required_by_default = false

    belongs_to :payment_method
    belongs_to :user

    has_many :payments, as: :source, dependent: :nullify

    before_save :set_last_digits

    attr_accessor :verification_value
    attr_reader :number
    attr_writer :save_requested_by_customer # For holding customer preference in memory

    validates :month, :year, numericality: { only_integer: true }
    validates :number, presence: true, unless: :has_payment_profile?, on: :create
    validates :verification_value, presence: true, unless: :has_payment_profile?, on: :create
    validate :expiry_not_in_the_past

    after_create :ensure_single_default_card
    after_save :ensure_single_default_card, if: :default_card_needs_updating?

    scope :with_payment_profile, -> { where.not(gateway_customer_profile_id: nil) }

    # needed for some of the ActiveMerchant gateways (eg. SagePay)
    alias_attribute :brand, :cc_type

    def expiry=(expiry)
      self[:month], self[:year] = expiry.split(" / ")
      self[:year] = "20#{self[:year]}"
    end

    def number=(num)
      @number = begin
        num.gsub(/[^0-9]/, '')
      rescue StandardError
        nil
      end
    end

    def cc_type=(type)
      reformat_card_type!(type)
    end

    def set_last_digits
      self.last_digits ||= number.to_s.length <= 4 ? number : number.to_s.slice(-4..-1)
    end

    def name?
      first_name? && last_name?
    end

    def name
      "#{first_name} #{last_name}"
    end

    def verification_value?
      verification_value.present?
    end

    # Show the card number, with all but last 4 numbers replace with "X". (XXXX-XXXX-XXXX-4338)
    def display_number
      "XXXX-XXXX-XXXX-#{last_digits}"
    end

    def can_resend_authorization_email?(payment)
      payment.requires_authorization?
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

    # Allows us to use a gateway_payment_profile_id to store Stripe Tokens
    def has_payment_profile?
      gateway_customer_profile_id.present? || gateway_payment_profile_id.present?
    end

    def to_active_merchant
      ActiveMerchant::Billing::CreditCard.new(
        number:,
        month:,
        year:,
        verification_value:,
        first_name:,
        last_name:
      )
    end

    def save_requested_by_customer?
      !!@save_requested_by_customer
    end

    private

    def reformat_card_type!(type)
      self[:cc_type] = active_merchant_card_type(type)
    end

    # ActiveMerchant requires certain credit card brand names to be stored in a specific format.
    # See: https://github.com/activemerchant/active_merchant/blob/master/lib/active_merchant/billing/credit_card.rb#L89
    def active_merchant_card_type(type)
      card_type = type.to_s.downcase

      case card_type
      when "mastercard", "maestro", "master card"
        "master"
      when "amex", "american express"
        "american_express"
      when "dinersclub", "diners club"
        "diners_club"
      else
        card_type
      end
    end

    def expiry_not_in_the_past
      return unless year.present? && month.present?

      time = "#{year}-#{month}-1".to_time
      return unless time < Time.zone.now.to_time.beginning_of_month

      errors.add(:base, :card_expired)
    end

    def reusable?
      gateway_customer_profile_id.present?
    end

    def default_missing?
      !user.credit_cards.where(is_default: true).exists?
    end

    def default_card_needs_updating?
      saved_change_to_is_default? || saved_change_to_gateway_customer_profile_id?
    end

    def ensure_single_default_card
      return unless user
      return unless is_default? || (reusable? && default_missing?)

      user.credit_cards.update_all(['is_default=(id=?)', id])
      self.is_default = true
    end
  end
end
