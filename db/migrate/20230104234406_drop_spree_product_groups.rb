# frozen_string_literal: true

class DropSpreeProductGroups < ActiveRecord::Migration[6.1]
  def change
    drop_table "spree_product_groups", id: :serial, force: :cascade do |t|
      t.string "name", limit: 255
      t.string "permalink", limit: 255
      t.string "order", limit: 255
      t.index ["name"], name: "index_product_groups_on_name"
      t.index ["permalink"], name: "index_product_groups_on_permalink"
    end
  end
end
