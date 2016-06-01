class AddIsDefaultToTagRule < ActiveRecord::Migration
  def change
    add_column :tag_rules, :is_default, :boolean, default: false, null: false
  end
end
