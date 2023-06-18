# frozen_string_literal: true

class CreateInvoices < ActiveRecord::Migration[6.1]
  def change
    create_table :invoices do |t|
      t.references :order, foreign_key: { to_table: :spree_orders }
      t.string :status
      t.integer :number
      t.jsonb :data
      t.date :date, default: -> { "CURRENT_TIMESTAMP" }, nil: false

      t.timestamps
    end
  end
end
