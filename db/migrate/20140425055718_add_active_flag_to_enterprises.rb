class AddActiveFlagToEnterprises < ActiveRecord::Migration
  def change
    add_column :enterprises, :active, :boolean, default: true
  end
end
