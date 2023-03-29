class AddHideOfnNavigationToEnterprises < ActiveRecord::Migration[7.0]
  def change
    add_column :enterprises, :hide_ofn_navigation, :boolean, null: false, default: false
  end
end
