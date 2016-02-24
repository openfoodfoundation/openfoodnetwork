class AddAccountInvoiceToBillablePeriods < ActiveRecord::Migration
  def change
    add_column :billable_periods, :account_invoice_id, :integer, null: false
    add_index :billable_periods, :account_invoice_id
    add_foreign_key :billable_periods, :account_invoices, column: :account_invoice_id
  end
end
