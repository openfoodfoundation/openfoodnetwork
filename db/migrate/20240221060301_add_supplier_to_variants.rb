class AddSupplierToVariants < ActiveRecord::Migration[7.0]
  def change
    add_reference :spree_variants, :supplier, foreign_key: { to_table: :enterprises }
  end
end
