# This migration comes from spree (originally 20140124023232)
class RenameActivatorIdInRulesAndActionsToPromotionId < ActiveRecord::Migration
  def change
    rename_column :spree_promotion_rules, :activator_id, :promotion_id
    rename_column :spree_promotion_actions, :activator_id, :promotion_id
  end
end
