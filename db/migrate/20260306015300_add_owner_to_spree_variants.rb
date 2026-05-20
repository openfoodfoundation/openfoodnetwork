# frozen_string_literal: true

class AddOwnerToSpreeVariants < ActiveRecord::Migration[7.1]
  def change
    add_reference :spree_variants, :owner, foreign_key: { to_table: :enterprises }
  end
end
