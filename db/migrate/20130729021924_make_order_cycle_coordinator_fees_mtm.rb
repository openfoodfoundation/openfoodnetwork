class MakeOrderCycleCoordinatorFeesMtm < ActiveRecord::Migration
  def up
    remove_column :order_cycles, :coordinator_admin_fee_id
    remove_column :order_cycles, :coordinator_sales_fee_id

    create_table :coordinator_fees, id: false do |t|
      t.references :order_cycle
      t.references :enterprise_fee
    end
  end

  def down
    drop_table :coordinator_fees

    add_column :order_cycles, :coordinator_admin_fee_id, :integer
    add_column :order_cycles, :coordinator_sales_fee_id, :integer
  end

end
