class AddTypeToEnterprises < ActiveRecord::Migration
  def up
    add_column :enterprises, :type, :string, null: false, default: 'profile'
    Enterprise.update_all type: 'full'
  end

  def down
    remove_column :enterprises, :type
  end
end
