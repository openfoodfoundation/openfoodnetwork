# frozen_string_literal: true

class RemoveSupplierAndHubFromVariants < ActiveRecord::Migration[7.2]
  def change
    remove_reference :spree_variants, :supplier, foreign_key: { to_table: :enterprises }
    remove_reference :spree_variants, :hub, foreign_key: { to_table: :enterprises }
  end
end
