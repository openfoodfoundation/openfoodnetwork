class AddEnterpriseFeeToProductDistributions < ActiveRecord::Migration
  def change
    add_column :product_distributions, :enterprise_fee_id, :integer
  end
end
