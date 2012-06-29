# This migration comes from spree_paypal_express (originally 20100224133156)
class CreatePaypalAccounts < ActiveRecord::Migration
  def self.up
    create_table :paypal_accounts do |t|
      t.string :email
      t.string :payer_id
      t.string :payer_country
      t.string :payer_status
    end
  end

  def self.down
    drop_table :paypal_accounts
  end
end
