# This migration comes from spree (originally 20131118043959)
class AddIncludedToAdjustments < ActiveRecord::Migration
  def change
    add_column :spree_adjustments, :included, :boolean, :default => false unless Spree::Adjustment.column_names.include?("included")
  end
end
