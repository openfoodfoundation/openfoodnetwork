# frozen_string_literal: true

class RequireOrderCycleAndEnterpriseFeeOnCoordinatorFees < ActiveRecord::Migration[7.0]
  def change
    change_column_null :coordinator_fees, :order_cycle_id, false
    change_column_null :coordinator_fees, :enterprise_fee_id, false
  end
end
