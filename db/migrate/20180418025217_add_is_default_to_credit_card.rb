class AddIsDefaultToCreditCard < ActiveRecord::Migration
  def change
    add_column :spree_credit_cards, :is_default, :boolean, default: false
  end
end
