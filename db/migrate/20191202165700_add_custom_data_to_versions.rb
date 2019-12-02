class AddCustomDataToVersions < ActiveRecord::Migration
  def change
    add_column :versions, :custom_data, :string
  end
end
