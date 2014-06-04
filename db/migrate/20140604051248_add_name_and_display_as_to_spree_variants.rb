class AddNameAndDisplayAsToSpreeVariants < ActiveRecord::Migration
  def change
    add_column :spree_variants, :name, :string
    add_column :spree_variants, :display_as, :string
  end
end
