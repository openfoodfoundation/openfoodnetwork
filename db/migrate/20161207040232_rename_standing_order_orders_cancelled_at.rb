class RenameStandingOrderOrdersCancelledAt < ActiveRecord::Migration
  def change
    # No, I'm not illiterate. I just want to maintain consistency with
    # existing Spree column names that are spelt using US English
    rename_column :standing_order_orders, :cancelled_at, :canceled_at
  end
end
