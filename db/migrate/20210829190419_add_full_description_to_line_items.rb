class AddFullDescriptionToLineItems < ActiveRecord::Migration[6.1]
  def change
    add_column :spree_line_items, :full_description, :string, limit: 255
  end
end
