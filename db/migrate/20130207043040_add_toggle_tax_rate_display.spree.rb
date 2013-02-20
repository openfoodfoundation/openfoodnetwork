# This migration comes from spree (originally 20120905151823)
class AddToggleTaxRateDisplay < ActiveRecord::Migration
  def change
    add_column :spree_tax_rates, :show_rate_in_label, :boolean, :default => true
  end
end
