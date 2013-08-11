module Spree
  Adjustment.class_eval do
    scope :enterprise_fee, where(originator_type: 'EnterpriseFee')
  end
end
