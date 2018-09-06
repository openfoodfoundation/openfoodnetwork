# This migration comes from spree (originally 20130516151222)
class AddPropageAllVariantsToSpreeStockLocation < ActiveRecord::Migration
  def change
    add_column :spree_stock_locations, :propagate_all_variants, :boolean, default: true
  end
end
