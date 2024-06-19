class RequireNameAndCoordinatorOnOrderCycle < ActiveRecord::Migration[7.0]
  def change
    change_column_null :order_cycles, :name, false
    change_column_null :order_cycles, :coordinator_id, false
  end
end
