class DropSpreePromotionTables < ActiveRecord::Migration[7.0]
  def change
    drop_table :spree_products_promotion_rules
    drop_table :spree_promotion_action_line_items
    drop_table :spree_promotion_actions
    drop_table :spree_promotion_rules
    drop_table :spree_promotion_rules_users
  end
end
