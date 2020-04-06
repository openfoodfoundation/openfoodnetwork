# This migration comes from spree (originally 20130413230529)
class AddNameToSpreeCreditCards < ActiveRecord::Migration
  def change
    add_column :spree_credit_cards, :name, :string
  end
end
