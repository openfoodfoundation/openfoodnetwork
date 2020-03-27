class ChangeVersionsCustomDataToText < ActiveRecord::Migration
  def up
    change_column :versions, :custom_data, :text
  end

  def down
    change_column :versions, :custom_data, :string
  end
end
