# This migration comes from spree (originally 20130708052307)
class AddDeletedAtToSpreeTaxRates < ActiveRecord::Migration
  def change
    add_column :spree_tax_rates, :deleted_at, :datetime
  end
end
