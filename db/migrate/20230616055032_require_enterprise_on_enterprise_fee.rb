# frozen_string_literal: true

class RequireEnterpriseOnEnterpriseFee < ActiveRecord::Migration[7.0]
  def change
    change_column_null :enterprise_fees, :enterprise_id, false
  end
end
