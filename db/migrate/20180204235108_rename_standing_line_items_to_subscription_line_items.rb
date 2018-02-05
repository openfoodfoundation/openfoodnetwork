class RenameStandingLineItemsToSubscriptionLineItems < ActiveRecord::Migration
  def up
    remove_foreign_key :standing_line_items, name: :oc_standing_line_items_variant_id_fk
    remove_foreign_key :standing_line_items, name: :standing_line_items_subscription_id_fk

    rename_table :standing_line_items, :subscription_line_items

    rename_index :subscription_line_items, :index_standing_line_items_on_subscription_id, :index_subscription_line_items_on_subscription_id
    rename_index :subscription_line_items, :index_standing_line_items_on_variant_id, :index_subscription_line_items_on_variant_id

    add_foreign_key :subscription_line_items, :spree_variants, name: :subscription_line_items_variant_id_fk, column: :variant_id
    add_foreign_key :subscription_line_items, :subscriptions, name: :subscription_line_items_subscription_id_fk
  end

  def down
    remove_foreign_key :subscription_line_items, name: :subscription_line_items_variant_id_fk
    remove_foreign_key :subscription_line_items, name: :subscription_line_items_subscription_id_fk

    rename_table :subscription_line_items, :standing_line_items

    rename_index :standing_line_items, :index_subscription_line_items_on_subscription_id, :index_standing_line_items_on_subscription_id
    rename_index :standing_line_items, :index_subscription_line_items_on_variant_id, :index_standing_line_items_on_variant_id

    add_foreign_key :standing_line_items, :spree_variants, name: :oc_standing_line_items_variant_id_fk, column: :variant_id
    add_foreign_key :standing_line_items, :subscriptions, name: :standing_line_items_subscription_id_fk
  end
end
