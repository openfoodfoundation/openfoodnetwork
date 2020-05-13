# frozen_string_literal: true

module Spree
  class StockItem < ActiveRecord::Base
    belongs_to :stock_location, class_name: 'Spree::StockLocation'
    belongs_to :variant, class_name: 'Spree::Variant'
    has_many :stock_movements, dependent: :destroy

    validates_presence_of :stock_location, :variant
    validates_uniqueness_of :variant_id, scope: :stock_location_id

    attr_accessible :count_on_hand, :variant, :stock_location, :backorderable, :variant_id

    delegate :weight, to: :variant

    def backordered_inventory_units
      Spree::InventoryUnit.backordered_for_stock_item(self)
    end

    delegate :name, to: :variant, prefix: true

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

    def count_on_hand=(value)
      self[:count_on_hand] = value
    end

    def process_backorders
      backordered_inventory_units.each do |unit|
        return unless in_stock?

        unit.fill_backorder
      end
    end
  end
end
