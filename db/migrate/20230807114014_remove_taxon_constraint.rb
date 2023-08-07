class RemoveTaxonConstraint < ActiveRecord::Migration[7.0]
  def change
    change_column_null :spree_products, :primary_taxon_id, true
  end
end
