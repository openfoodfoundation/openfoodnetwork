# This migration comes from spree_paypal_express (originally 20130809013846)
class AddStateToSpreePaypalExpressCheckouts < ActiveRecord::Migration
  def change
    add_column :spree_paypal_express_checkouts, :state, :string, :default => "complete"
  end
end
