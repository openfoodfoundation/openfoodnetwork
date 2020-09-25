class AddTimezoneToEnterprises < ActiveRecord::Migration
  def change
    add_column :enterprises, :timezone, :string
  end
end
