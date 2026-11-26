# frozen_string_literal: true

class CreateSpreePaypalRestCheckouts < ActiveRecord::Migration[7.2]
  def change
    create_table :spree_paypal_rest_checkouts do |t|
      t.string :order_id, null: false
      t.string :capture_id
      t.string :payer_id
      t.string :status
      t.string :refund_id
      t.datetime :refunded_at

      t.timestamps
    end

    add_index :spree_paypal_rest_checkouts, :order_id, unique: true
    add_index :spree_paypal_rest_checkouts, :capture_id
    add_index :spree_paypal_rest_checkouts, :refund_id
  end
end
