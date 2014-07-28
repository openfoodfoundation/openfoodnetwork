# This migration comes from spree_paypal_express (originally 20130723042610)
class CreateSpreePaypalExpressCheckouts < ActiveRecord::Migration
  def change
    create_table :spree_paypal_express_checkouts do |t|
      t.string :token
      t.string :payer_id
    end
  end
end
