class AddPriorityToTagRule < ActiveRecord::Migration
  def change
    add_column :tag_rules, :priority, :integer, default: 99, null: false
  end
end
