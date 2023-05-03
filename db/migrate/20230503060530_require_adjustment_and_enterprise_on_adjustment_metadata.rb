# frozen_string_literal: true

class RequireAdjustmentAndEnterpriseOnAdjustmentMetadata < ActiveRecord::Migration[7.0]
  def change
    change_column_null :adjustment_metadata, :adjustment_id, false
    change_column_null :adjustment_metadata, :enterprise_id, false
  end
end
