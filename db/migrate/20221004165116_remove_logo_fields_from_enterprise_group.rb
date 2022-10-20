class RemoveLogoFieldsFromEnterpriseGroup < ActiveRecord::Migration[6.1]
  def change
    remove_column :enterprise_groups, :logo_file_name, :string
    remove_column :enterprise_groups, :logo_content_type, :string
    remove_column :enterprise_groups, :logo_file_size, :integer
    remove_column :enterprise_groups, :logo_updated_at, :datetime
  end
end
