class AddRemovedColumnToEnterprises < ActiveRecord::Migration[7.0]
  def change
    add_column :enterprises, :removed, :boolean, default: false
  end
end
