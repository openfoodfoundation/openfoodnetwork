# frozen_string_literal: true

class AddHubToSpreeVariants < ActiveRecord::Migration[7.1]
  def change
    add_reference :spree_variants, :hub, foreign_key: { to_table: :enterprises }
  end
end
