class RequireOrderCycleAndSenderAndReceiverOnExchange < ActiveRecord::Migration[7.0]
  def change
    change_column_null :exchanges, :order_cycle_id, false
    change_column_null :exchanges, :sender_id, false
    change_column_null :exchanges, :receiver_id, false
  end
end
