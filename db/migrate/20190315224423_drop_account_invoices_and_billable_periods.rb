class DropAccountInvoicesAndBillablePeriods < ActiveRecord::Migration
  def up
    drop_table :billable_periods
    drop_table :account_invoices
  end
end
