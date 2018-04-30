# This migration comes from spree (originally 20130325163316)
class MigrateInventoryUnitSoldToOnHand < ActiveRecord::Migration
  def up
    Spree::InventoryUnit.where(:state => 'sold').update_all(:state => 'on_hand')
  end

  def down
    Spree::InventoryUnit.where(:state => 'on_hand').update_all(:state => 'sold')
  end
end
