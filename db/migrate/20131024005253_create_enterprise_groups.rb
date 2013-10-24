class CreateEnterpriseGroups < ActiveRecord::Migration
  def change
    create_table :enterprise_groups do |t|
      t.string :name
      t.boolean :on_front_page
    end

    create_table :enterprise_groups_enterprises, id: false do |t|
      t.references :enterprise_group
      t.references :enterprise
    end
  end
end
