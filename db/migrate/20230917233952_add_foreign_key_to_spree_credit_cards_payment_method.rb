class AddForeignKeyToSpreeCreditCardsPaymentMethod < ActiveRecord::Migration[6.0]
  def change
    add_foreign_key :spree_credit_cards, :spree_payment_methods, on_delete: :cascade
  end
end
