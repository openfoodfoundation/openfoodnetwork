class AddPositionToEnterpriseGroups < ActiveRecord::Migration
  def change
    add_column :enterprise_groups, :position, :integer
  end
end
