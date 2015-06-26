class RenameBillItemsToBillablePeriods < ActiveRecord::Migration
  def up
    rename_table :bill_items, :billable_periods
  end

  def down
    rename_table :billable_periods, :bill_items
  end
end
