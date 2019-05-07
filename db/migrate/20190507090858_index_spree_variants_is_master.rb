class IndexSpreeVariantsIsMaster < ActiveRecord::Migration
  def change
    add_index :spree_variants, :is_master
  end
end
