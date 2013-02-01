class ChangeExchangePickupTimeToString < ActiveRecord::Migration
  def up
    change_column :exchanges, :pickup_time, :string
  end

  def down
    change_column :exchanges, :pickup_time, :datetime
  end
end
