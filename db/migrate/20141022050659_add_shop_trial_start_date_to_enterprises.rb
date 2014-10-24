class AddShopTrialStartDateToEnterprises < ActiveRecord::Migration
  def change
    add_column :enterprises, :shop_trial_start_date, :datetime, default: nil
  end
end
