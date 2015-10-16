class AddTimestampsToBillablePeriods < ActiveRecord::Migration
  def change
    change_table(:billable_periods) do |t|
      t.datetime :deleted_at, default: nil
      t.timestamps
    end
  end
end
