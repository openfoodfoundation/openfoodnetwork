class AddCustomDataToVersions < ActiveRecord::Migration[4.2]
  def change
    add_column :versions, :custom_data, :string
  end
end
