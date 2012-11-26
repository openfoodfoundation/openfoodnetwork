class CreateOrderCycles < ActiveRecord::Migration
  def change
    create_table :order_cycles do |t|
      t.string :name
      t.datetime :orders_open_at
      t.datetime :orders_close_at
      t.references :coordinator
      t.references :coordinator_admin_fee
      t.references :coordinator_sales_fee
      t.timestamps
    end

    create_table :exchanges do |t|
      t.references :order_cycle
      t.references :sender
      t.references :receiver
      t.references :payment_enterprise
      t.datetime :pickup_time
      t.string :pickup_instructions
      t.timestamps
    end

    create_table :exchange_variants do |t|
      t.references :exchange
      t.references :variant
      t.timestamps
    end

    create_table :exchange_fees do |t|
      t.references :exchange
      t.references :enterprise_fee
      t.timestamps
    end
  end
end
