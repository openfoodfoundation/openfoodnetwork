class DropEnterpriseShopTrialStartDate < ActiveRecord::Migration[4.2]
  def up
    remove_column :enterprises, :shop_trial_start_date
  end

  def down
    add_column :enterprises, :shop_trial_start_date, :datetime, default: nil
  end
end
