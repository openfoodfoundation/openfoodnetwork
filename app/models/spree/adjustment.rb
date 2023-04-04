# frozen_string_literal: true

require 'spree/localized_number'
require 'concerns/adjustment_scopes'

# Adjustments represent a change to the +item_total+ of an Order. Each adjustment
# has an +amount+ that can be either positive or negative.
#
# Adjustments can be open/closed/finalized
#
# Once an adjustment is finalized, it cannot be changed, but an adjustment can
# toggle between open/closed as needed
#
# Boolean attributes:
#
# +mandatory+
#
# If this flag is set to true then it means the the charge is required and will not
# be removed from the order, even if the amount is zero. In other words a record
# will be created even if the amount is zero. This is useful for representing things
# such as shipping and tax charges where you may want to make it explicitly clear
# that no charge was made for such things.
#
# +eligible?+
#
# This boolean attributes stores whether this adjustment is currently eligible
# for its order. Only eligible adjustments count towards the order's adjustment
# total. This allows an adjustment to be preserved if it becomes ineligible so
# it might be reinstated.
module Spree
  class Adjustment < ApplicationRecord
    extend Spree::LocalizedNumber

    # Deletion of metadata is handled in the database.
    # So we don't need the option `dependent: :destroy` as long as
    # AdjustmentMetadata has no destroy logic itself.
    has_one :metadata, class_name: 'AdjustmentMetadata'
    has_many :adjustments, as: :adjustable, dependent: :destroy

    belongs_to :adjustable, polymorphic: true
    belongs_to :originator, -> { with_deleted }, polymorphic: true
    belongs_to :order, class_name: "Spree::Order"
    belongs_to :tax_category, class_name: 'Spree::TaxCategory'

    belongs_to :tax_rate, -> { where spree_adjustments: { originator_type: 'Spree::TaxRate' } },
               foreign_key: 'originator_id'
    belongs_to :voucher, -> { where spree_adjustments: { originator_type: 'Spree::Voucher' } },
               foreign_key: 'originator_id', inverse_of: :adjustments

    validates :label, presence: true
    validates :amount, numericality: true

    after_create :update_adjustable_adjustment_total

    state_machine :state, initial: :open do
      event :close do
        transition from: :open, to: :closed
      end

      event :open do
        transition from: :closed, to: :open
      end

      event :finalize do
        transition from: [:open, :closed], to: :finalized
      end
    end

    scope :tax, -> { where(originator_type: 'Spree::TaxRate') }
    scope :price, -> { where(adjustable_type: 'Spree::LineItem') }
    scope :optional, -> { where(mandatory: false) }
    scope :charge, -> { where('amount >= 0') }
    scope :credit, -> { where('amount < 0') }
    scope :return_authorization, -> { where(originator_type: "Spree::ReturnAuthorization") }
    scope :inclusive, -> { where(included: true) }
    scope :additional, -> { where(included: false) }
    scope :legacy_tax, -> { additional.tax.where(adjustable_type: "Spree::Order") }

    scope :enterprise_fee, -> { where(originator_type: 'EnterpriseFee') }
    scope :admin,          -> { where(originator_type: nil) }

    scope :payment_fee,    -> { where(AdjustmentScopes::PAYMENT_FEE_SCOPE) }
    scope :shipping,       -> { where(AdjustmentScopes::SHIPPING_SCOPE) }
    scope :eligible,       -> { where(AdjustmentScopes::ELIGIBLE_SCOPE) }

    localize_number :amount

    # Update both the eligibility and amount of the adjustment. Adjustments
    # delegate updating of amount to their Originator when present, but only if
    # +locked+ is false. Adjustments that are +locked+ will never change their amount.
    #
    # Adjustments delegate updating of amount to their Originator when present,
    # but only if when they're in "open" state, closed or finalized adjustments
    # are not recalculated.
    #
    # It receives +calculable+ as the updated source here so calculations can be
    # performed on the current values of that source. If we used +source+ it
    # could load the old record from db for the association. e.g. when updating
    # more than on line items at once via accepted_nested_attributes the order
    # object on the association would be in a old state and therefore the
    # adjustment calculations would not performed on proper values
    def update_adjustment!(calculable = nil, force: false)
      return amount if immutable? && !force

      if calculable.nil? && adjustable.nil?
        delete
        return 0.0
      end

      if originator.present?
        amount = originator.compute_amount(calculable || adjustable)
        update_columns(
          amount: amount,
          updated_at: Time.zone.now,
        )
      end

      amount
    end

    def currency
      adjustable ? adjustable.currency : Spree::Config[:currency]
    end

    def display_amount
      Spree::Money.new(amount, currency: currency)
    end

    def admin?
      originator_type.nil?
    end

    def immutable?
      state != "open"
    end

    def has_tax?
      tax_total.positive?
    end

    def included_tax_total
      adjustments.tax.inclusive.sum(:amount)
    end

    def additional_tax_total
      adjustments.tax.additional.sum(:amount)
    end

    private

    def tax_total
      adjustments.tax.sum(:amount)
    end

    def update_adjustable_adjustment_total
      Spree::ItemAdjustments.new(adjustable).update if adjustable
    end
  end
end
