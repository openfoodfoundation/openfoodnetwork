class AddSendOrderConfirmEmailToShopToOrderCycles < ActiveRecord::Migration[6.1]
  def change
    add_column :order_cycles, :send_order_confirm_email_to_shop, :boolean, default: true
  end
end
