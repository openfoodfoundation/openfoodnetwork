class AddUserIdToSpreeCreditCards < ActiveRecord::Migration
  def change
    unless Spree::CreditCard.column_names.include? "user_id"
      add_column :spree_credit_cards, :user_id, :integer
      add_index :spree_credit_cards, :user_id
    end
  end
end
