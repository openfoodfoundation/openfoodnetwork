class AddHideGroupsTabToEnterprises < ActiveRecord::Migration[7.0]
  def change
    add_column :enterprises, :hide_groups_tab, :boolean, default: false
  end
end
