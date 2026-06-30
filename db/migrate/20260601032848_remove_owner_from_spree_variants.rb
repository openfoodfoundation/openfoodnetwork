# frozen_string_literal: true

class RemoveOwnerFromSpreeVariants < ActiveRecord::Migration[7.1]
  def change
    remove_reference :spree_variants, :owner, foreign_key: { to_table: :enterprises }
  end
end
