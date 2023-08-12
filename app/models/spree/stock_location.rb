# frozen_string_literal: true

module Spree
  class StockLocation < ApplicationRecord
    self.belongs_to_required_by_default = false

    has_many :stock_items, dependent: :delete_all, inverse_of: :stock_location
    has_many :stock_movements, through: :stock_items

    belongs_to :state, class_name: 'Spree::State'
    belongs_to :country, class_name: 'Spree::Country'

    validates :name, presence: true

    scope :active, -> { where(active: true) }

    after_create :create_stock_items

    # Wrapper for creating a new stock item respecting the backorderable config
    def propagate_variant(variant)
      stock_items.create!(variant: variant, backorderable: backorderable_default)
    end

    def stock_item(variant)
      stock_items.where(variant_id: variant).order(:id).first
    end

    def stock_item_or_create(variant)
      stock_item(variant) || stock_items.create(variant: variant)
    end

    def count_on_hand(variant)
      stock_item(variant).try(:count_on_hand)
    end

    def backorderable?(variant)
      stock_item(variant).try(:backorderable?)
    end

    def restock(variant, quantity, originator = nil)
      move(variant, quantity, originator)
    end

    def unstock(variant, quantity, originator = nil)
      move(variant, -quantity, originator)
    end

    def move(variant, quantity, originator = nil)
      variant.move(quantity, originator)
    end

    def fill_status(variant, quantity)
      variant.fill_status(quantity)
    end

    private

    def create_stock_items
      Variant.find_each { |variant| propagate_variant(variant) }
    end
  end
end
