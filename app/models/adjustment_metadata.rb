# frozen_string_literal: true

class AdjustmentMetadata < ApplicationRecord
  self.belongs_to_required_by_default = true

  belongs_to :adjustment, class_name: 'Spree::Adjustment'
  belongs_to :enterprise
end
