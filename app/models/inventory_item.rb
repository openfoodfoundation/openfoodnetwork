class InventoryItem < ActiveRecord::Base
  attr_accessible :enterprise_id, :variant_id, :visible

  belongs_to :enterprise
  belongs_to :variant, class_name: "Spree::Variant"

  validates :variant_id, uniqueness: { scope: :enterprise_id }

  scope :visible, where(visible: true)
  scope :hidden, where(visible: false)
end
