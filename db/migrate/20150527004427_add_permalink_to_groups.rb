class AddPermalinkToGroups < ActiveRecord::Migration
  def up
    add_column :enterprise_groups, :permalink, :string

    EnterpriseGroup.reset_column_information

    EnterpriseGroup.all.each do |group|
      counter = 1
      permalink = group.name.parameterize
      permalink = "my-group-name" if permalink == ""
      while EnterpriseGroup.find_by_permalink(permalink) do
        permalink = group.name.parameterize + counter.to_s
        counter += 1
      end

      group.update_column :permalink, permalink
    end

    change_column :enterprise_groups, :permalink, :string, null: false
    add_index :enterprise_groups, :permalink, :unique => true
  end

  def down
    remove_column :enterprise_groups, :permalink
  end
end
