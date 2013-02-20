# This migration comes from spree (originally 20121111231553)
class RemoveDisplayOnFromPaymentMethods < ActiveRecord::Migration
  def up
    remove_column :spree_payment_methods, :display_on
  end
  
  def down
    add_column :spree_payment_methods, :display_on, :string
  end
end
