class RemoveProductTaxonsTable < ActiveRecord::Migration[7.0]
  def change
    remove_foreign_key "spree_products_taxons", "spree_products", column: "product_id", name: "spree_products_taxons_product_id_fk", on_delete: :cascade
    remove_foreign_key "spree_products_taxons", "spree_taxons", column: "taxon_id", name: "spree_products_taxons_taxon_id_fk", on_delete: :cascade

    drop_table :spree_products_taxons do |t|
      t.integer "product_id"
      t.integer "taxon_id"
      t.index ["product_id"], name: "index_products_taxons_on_product_id"
      t.index ["taxon_id"], name: "index_products_taxons_on_taxon_id"
    end
  end
end
