class DropVariantIsMaster < ActiveRecord::Migration[7.0]
  def up
    remove_column :spree_variants, :is_master
  end
end
