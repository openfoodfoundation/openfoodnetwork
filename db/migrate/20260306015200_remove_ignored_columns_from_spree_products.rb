# frozen_string_literal: true

class RemoveIgnoredColumnsFromSpreeProducts < ActiveRecord::Migration[6.1]
  def change
    change_table :spree_products, bulk: true do
      remove_column :spree_products, :primary_taxon_id, :integer
      remove_column :spree_products, :variant_unit, :string
      remove_column :spree_products, :variant_unit_scale, :float
      remove_column :spree_products, :variant_unit_name, :string
    end
  end
end
