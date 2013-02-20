# This migration comes from spree (originally 20130114053446)
class AddDisplayOnToSpreePaymentMethods < ActiveRecord::Migration
  def self.up
    add_column :spree_payment_methods, :display_on, :string
  end

  def self.down
    remove_column :spree_payment_methods, :display_on
  end
end
