module Spree
  Adjustment.class_eval do
    has_one :metadata, class_name: 'AdjustmentMetadata', dependent: :destroy

    scope :enterprise_fee, where(originator_type: 'EnterpriseFee')
    scope :included_tax, where(originator_type: 'Spree::TaxRate', adjustable_type: 'Spree::LineItem')

    attr_accessible :included_tax

    def set_included_tax!(rate)
      tax = amount - (amount / (1 + rate))
      set_absolute_included_tax! tax
    end

    def set_absolute_included_tax!(tax)
      update_attributes! included_tax: tax.round(2)
    end
  end
end
