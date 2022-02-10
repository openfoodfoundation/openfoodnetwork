class AddMailsSentToOrderCycles < ActiveRecord::Migration[6.1]
  def change
    add_column :order_cycles, :mails_sent, :boolean, default: false
  end
end
