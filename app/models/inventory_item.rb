# frozen_string_literal: true

class InventoryItem < ApplicationRecord
  belongs_to :enterprise
  belongs_to :variant, class_name: "Spree::Variant"

  validates :variant_id, uniqueness: { scope: :enterprise_id }
  validates :visible,
            inclusion: { in: [true, false], message: I18n.t(:inventory_item_visibility_error) }

  scope :visible, -> { where(visible: true) }
  scope :hidden, -> { where(visible: false) }
end
