# frozen_string_literal: true

class RemoveSupplierIdFromSpreeProducts < ActiveRecord::Migration[6.1]
  def change
    remove_foreign_key :spree_products, :enterprises, column: :supplier_id,
                                                      name: :spree_products_supplier_id_fk
    remove_index :spree_products, :supplier_id
    remove_column :spree_products, :supplier_id, :integer
  end
end
