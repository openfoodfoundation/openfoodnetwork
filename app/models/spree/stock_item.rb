# frozen_string_literal: true

module Spree
  class StockItem < ApplicationRecord
    acts_as_paranoid

    # WIP: phasing out stock location, it's not used.
    belongs_to :stock_location, class_name: 'Spree::StockLocation', inverse_of: :stock_items,
                                optional: true
    belongs_to :variant, -> { with_deleted }, class_name: 'Spree::Variant'
    has_many :stock_movements, dependent: :destroy

    validates :variant_id, uniqueness: { scope: [:stock_location_id, :deleted_at] }
    validates :count_on_hand, numericality: { greater_than_or_equal_to: 0, unless: :backorderable? }

    delegate :weight, to: :variant
    delegate :name, to: :variant, prefix: true

    def backordered_inventory_units
      Spree::InventoryUnit.backordered_for_stock_item(self)
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

    def count_on_hand=(value)
      self[:count_on_hand] = value
    end

    # Other code still calls this.
    # TODO: remove usage
    def stock_location
      @stock_location ||= DefaultStockLocation.find_or_create
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
