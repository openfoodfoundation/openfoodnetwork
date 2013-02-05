# This migration comes from spree (originally 20121111231553)
class RemoveDisplayOnFromPaymentMethods < ActiveRecord::Migration
  def up
    remove_column :spree_payment_methods, :display_on
  end
end
