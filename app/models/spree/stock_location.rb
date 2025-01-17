# frozen_string_literal: true

module Spree
  class StockLocation < ApplicationRecord
    self.belongs_to_required_by_default = false
    self.ignored_columns += [:backorderable_default, :active]

    has_many :stock_items, dependent: :delete_all, inverse_of: :stock_location
    has_many :stock_movements, through: :stock_items

    belongs_to :state, class_name: 'Spree::State'
    belongs_to :country, class_name: 'Spree::Country'

    validates :name, presence: true

    # Wrapper for creating a new stock item respecting the backorderable config
    def stock_item(variant)
      StockItem.where(variant_id: variant).order(:id).first
    end

    # We have only one default stock location and it may be unpersisted.
    # So all stock items belong to any unpersisted stock location.
    def stock_items
      StockItem.all
    end

    def stock_movements
      StockMovement.all
    end

    def stock_item_or_create(variant)
      stock_item(variant) || stock_items.create(variant:)
    end
  end
end
