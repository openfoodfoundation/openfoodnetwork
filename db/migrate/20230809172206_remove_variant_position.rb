class RemoveVariantPosition < ActiveRecord::Migration[7.0]
  def up
    remove_column :spree_variants, :position
  end
end
