# frozen_string_literal: true

module Spree
  class StockItem < ApplicationRecord
    self.ignored_columns += [:stock_location_id]

    acts_as_paranoid

    belongs_to :variant, -> { with_deleted }, class_name: 'Spree::Variant', inverse_of: :stock_items

    validates :variant_id, uniqueness: { scope: [:deleted_at] }
    validates :count_on_hand, numericality: { greater_than_or_equal_to: 0, unless: :backorderable? }

    delegate :weight, to: :variant
    delegate :name, to: :variant, prefix: true

    def backordered_inventory_units
      Spree::InventoryUnit.backordered_per_variant(self)
    end

    def adjust_count_on_hand(value)
      with_lock do
        self.count_on_hand = count_on_hand + value
        process_backorders if in_stock?

        save!
      end
    end

    def in_stock?
      count_on_hand.positive?
    end

    # Tells whether it's available to be included in a shipment
    def available?
      in_stock? || backorderable?
    end

    private

    def process_backorders
      backordered_inventory_units.each do |unit|
        break unless in_stock?

        unit.fill_backorder
      end
    end
  end
end
