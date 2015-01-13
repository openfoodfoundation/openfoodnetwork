module Spree
  Adjustment.class_eval do
    has_one :metadata, class_name: 'AdjustmentMetadata', dependent: :destroy

    scope :enterprise_fee, where(originator_type: 'EnterpriseFee')
    scope :included_tax, where(originator_type: 'Spree::TaxRate', adjustable_type: 'Spree::LineItem')
  end
end
