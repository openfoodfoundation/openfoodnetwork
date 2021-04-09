class SetBackorderedInventoryToOnHand < ActiveRecord::Migration[4.2]
  def up
    execute("UPDATE spree_inventory_units SET state = 'on_hand' WHERE state = 'backordered'")
  end
end
