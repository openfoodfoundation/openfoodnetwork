class AddForeignKeyToSpreeCreditCardsUser < ActiveRecord::Migration[6.0]
  def change
    add_foreign_key :spree_credit_cards, :spree_users, on_delete: :cascade
  end
end
