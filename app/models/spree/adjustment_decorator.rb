module Spree
  Adjustment.class_eval do
    has_one :metadata, class_name: 'AdjustmentMetadata'

    scope :enterprise_fee, where(originator_type: 'EnterpriseFee')
  end
end
