# This migration comes from spree (originally 20130226054936)
class AddVariantIdIndexToSpreePrices < ActiveRecord::Migration
  def change
    add_index :spree_prices, :variant_id
  end
end
