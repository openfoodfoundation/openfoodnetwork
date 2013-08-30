class AdjustmentMetadata < ActiveRecord::Base
  belongs_to :adjustment, class_name: 'Spree::Adjustment'
  belongs_to :enterprise
end
