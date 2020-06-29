require 'spree/localized_number'
require 'concerns/adjustment_scopes'

module Spree
  Adjustment.class_eval do
    extend Spree::LocalizedNumber

    # Deletion of metadata is handled in the database.
    # So we don't need the option `dependent: :destroy` as long as
    # AdjustmentMetadata has no destroy logic itself.
    has_one :metadata, class_name: 'AdjustmentMetadata'
    belongs_to :tax_rate, -> { where spree_adjustments: { originator_type: 'Spree::TaxRate' } },
               foreign_key: 'originator_id'

    scope :enterprise_fee, -> { where(originator_type: 'EnterpriseFee') }
    scope :admin,          -> { where(source_type: nil, originator_type: nil) }
    scope :included_tax,   -> {
      where(originator_type: 'Spree::TaxRate', adjustable_type: 'Spree::LineItem')
    }

    scope :with_tax,       -> { where('spree_adjustments.included_tax <> 0') }
    scope :without_tax,    -> { where('spree_adjustments.included_tax = 0') }
    scope :payment_fee,    -> { where(AdjustmentScopes::PAYMENT_FEE_SCOPE) }
    scope :shipping,       -> { where(AdjustmentScopes::SHIPPING_SCOPE) }
    scope :eligible,       -> { where(AdjustmentScopes::ELIGIBLE_SCOPE) }

    localize_number :amount

    def set_included_tax!(rate)
      tax = amount - (amount / (1 + rate))
      set_absolute_included_tax! tax
    end

    def set_absolute_included_tax!(tax)
      # This rubocop issue can only be fixed when Adjustment#update! is brought from Spree to OFN
      #   and renamed to something else, then AR's update! can be used instead of update_attributes!
      # rubocop:disable Rails/ActiveRecordAliases
      update_attributes! included_tax: tax.round(2)
      # rubocop:enable Rails/ActiveRecordAliases
    end

    def display_included_tax
      Spree::Money.new(included_tax, currency: currency)
    end

    def has_tax?
      included_tax > 0
    end

    def self.without_callbacks
      skip_callback :save, :after, :update_adjustable
      skip_callback :destroy, :after, :update_adjustable

      result = yield
    ensure
      set_callback :save, :after, :update_adjustable
      set_callback :destroy, :after, :update_adjustable

      result
    end
  end
end
