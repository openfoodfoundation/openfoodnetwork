class AddTaxonsToVariants < ActiveRecord::Migration[7.0]
  def change
    add_reference :spree_variants, :primary_taxon, foreign_key: { to_table: :spree_taxons }
  end
end
