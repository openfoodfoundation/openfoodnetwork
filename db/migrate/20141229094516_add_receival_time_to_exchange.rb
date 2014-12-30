class AddReceivalTimeToExchange < ActiveRecord::Migration
  def change
    add_column :exchanges, :receival_time, :string
    add_column :exchanges, :receival_instructions, :string
  end
end
