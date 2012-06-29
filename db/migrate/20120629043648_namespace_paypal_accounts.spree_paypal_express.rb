# This migration comes from spree_paypal_express (originally 20120117182027)
class NamespacePaypalAccounts < ActiveRecord::Migration
  def change
    rename_table :paypal_accounts, :spree_paypal_accounts
  end
end
