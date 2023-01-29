# frozen_string_literal: true

class DropSpreeSkrillTransactions < ActiveRecord::Migration[6.1]
  def change
    drop_table "spree_skrill_transactions", id: :serial, force: :cascade do |t|
      t.string "email", limit: 255
      t.float "amount"
      t.string "currency", limit: 255
      t.integer "transaction_id"
      t.integer "customer_id"
      t.string "payment_type", limit: 255
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
    end
  end
end
