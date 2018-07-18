class RemoveCreditCardFromSubscriptions < ActiveRecord::Migration
  def up
    remove_foreign_key :subscriptions, name: :subscriptions_credit_card_id_fk
    remove_index :subscriptions, :credit_card_id
    remove_column :subscriptions, :credit_card_id
  end

  def down
    add_column :subscriptions, :credit_card_id, :integer
    add_index :subscriptions, :credit_card_id
    add_foreign_key :subscriptions, :spree_credit_cards, name: :subscriptions_credit_card_id_fk, column: :credit_card_id
  end
end
