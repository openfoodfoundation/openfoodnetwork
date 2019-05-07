class IndexSpreeVariantsDeletedAt < ActiveRecord::Migration
  def change
    add_index :spree_variants, :deleted_at
  end
end
