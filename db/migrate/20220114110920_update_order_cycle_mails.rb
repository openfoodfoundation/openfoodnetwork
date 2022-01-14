class UpdateOrderCycleMails < ActiveRecord::Migration[6.1]
  class MigrationOrderCycle < ActiveRecord::Base
    self.table_name = "order_cycles"
  end

  def up
    MigrationOrderCycle.
      where(automatic_notifications: true).
      where.not(processed_at: nil).
      update_all(mails_sent: true)
  end
end
