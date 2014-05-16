class AddFieldsToGroups < ActiveRecord::Migration
  def change
    add_column :enterprise_groups, :description, :text
    add_column :enterprise_groups, :long_description, :text
  end
end
