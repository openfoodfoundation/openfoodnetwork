# frozen_string_literal: true

# This old Spree concept has never been used in our project.
class DropSpreeProductGroupsProducts < ActiveRecord::Migration[6.1]
  def change
    drop_table "spree_product_groups_products", id: false, force: :cascade do |t|
      t.integer "product_id"
      t.integer "product_group_id"
    end
  end
end
