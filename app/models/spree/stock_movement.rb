# frozen_string_literal: true

module Spree
  class StockMovement < ApplicationRecord
    belongs_to :stock_item, class_name: 'Spree::StockItem'
    belongs_to :originator, polymorphic: true, optional: true

    after_create :update_stock_item_quantity

    validates :quantity, presence: true

    scope :recent, -> { order('created_at DESC') }

    def readonly?
      !new_record?
    end

    private

    def update_stock_item_quantity
      stock_item.adjust_count_on_hand quantity
    end
  end
end
