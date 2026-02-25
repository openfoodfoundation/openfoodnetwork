# frozen_string_literal: true

class AddOwnerToSpreeVariants < ActiveRecord::Migration[7.1]
  def change
    add_column :spree_variants, :owner_id, :integer
    add_foreign_key :spree_variants, :enterprises, column: :owner_id
  end
end
