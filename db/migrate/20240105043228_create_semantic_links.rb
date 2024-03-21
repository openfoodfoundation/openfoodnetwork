# frozen_string_literal: true

class CreateSemanticLinks < ActiveRecord::Migration[7.0]
  def change
    create_table :semantic_links do |t|
      t.references :variant, null: false, foreign_key: { to_table: :spree_variants }
      t.string :semantic_id, null: false

      t.timestamps
    end
  end
end
