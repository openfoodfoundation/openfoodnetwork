class RenameActiveToVisibleOnEnterprises < ActiveRecord::Migration
  def change
    rename_column :enterprises, :active, :visible
  end
end
