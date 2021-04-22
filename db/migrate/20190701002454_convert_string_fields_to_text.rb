class ConvertStringFieldsToText < ActiveRecord::Migration[4.2]
  def up
    change_column :enterprises, :description, :text
    change_column :enterprises, :pickup_times, :text
    change_column :exchanges, :pickup_time, :text
    change_column :exchanges, :pickup_instructions, :text
    change_column :exchanges, :receival_instructions, :text
  end

  def down
    change_column :enterprises, :description, :string
    change_column :enterprises, :pickup_times, :string
    change_column :exchanges, :pickup_time, :string
    change_column :exchanges, :pickup_instructions, :string
    change_column :exchanges, :receival_instructions, :string
  end
end
