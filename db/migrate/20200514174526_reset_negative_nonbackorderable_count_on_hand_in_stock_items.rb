# frozen_string_literal: true

class ResetNegativeNonbackorderableCountOnHandInStockItems < ActiveRecord::Migration[4.2]
  module Spree
    class StockItem < ActiveRecord::Base
      self.table_name = "spree_stock_items"
    end
  end

  def up
    Spree::StockItem.where(backorderable: false)
      .where("count_on_hand < 0")
      .update_all(count_on_hand: 0)
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
