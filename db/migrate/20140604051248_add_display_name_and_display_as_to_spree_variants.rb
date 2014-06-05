class AddDisplayNameAndDisplayAsToSpreeVariants < ActiveRecord::Migration
  def change
    add_column :spree_variants, :display_name, :string
    add_column :spree_variants, :display_as, :string
  end
end
