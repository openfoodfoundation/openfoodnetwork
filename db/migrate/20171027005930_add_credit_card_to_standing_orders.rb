class AddCreditCardToStandingOrders < ActiveRecord::Migration
  def change
    add_column :standing_orders, :credit_card_id, :integer
    add_index :standing_orders, :credit_card_id
    add_foreign_key :standing_orders, :spree_credit_cards, name: :standing_orders_credit_card_id_fk, column: :credit_card_id
  end
end
