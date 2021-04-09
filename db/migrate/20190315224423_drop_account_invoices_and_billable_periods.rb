class DropAccountInvoicesAndBillablePeriods < ActiveRecord::Migration[4.2]
  def up
    drop_table :billable_periods
    drop_table :account_invoices
  end
end
