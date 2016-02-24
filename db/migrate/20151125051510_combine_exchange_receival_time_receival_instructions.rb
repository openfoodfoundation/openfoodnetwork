class CombineExchangeReceivalTimeReceivalInstructions < ActiveRecord::Migration
  def up
    remove_column :exchanges, :receival_time
  end

  def down
    add_column :exchanges, :receival_time, :string
  end
end
