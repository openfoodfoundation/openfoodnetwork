class AddOptionValuesLineItemsJoinTable < ActiveRecord::Migration
  def change
    create_table :spree_option_values_line_items, :id => false, :force => true do |t|
      t.integer  :line_item_id
      t.integer  :option_value_id
    end

    Spree::LineItem.all.each do |line_item|
      line_item.update_units
    end

    add_index :spree_option_values_line_items, :line_item_id, :name => 'index_option_values_line_items_on_line_item_id'
  end
end
