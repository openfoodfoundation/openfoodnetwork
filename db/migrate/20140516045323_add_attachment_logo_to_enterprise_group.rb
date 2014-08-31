class AddAttachmentLogoToEnterpriseGroup < ActiveRecord::Migration
  def self.up
    add_column :enterprise_groups, :logo_file_name, :string
    add_column :enterprise_groups, :logo_content_type, :string
    add_column :enterprise_groups, :logo_file_size, :integer
    add_column :enterprise_groups, :logo_updated_at, :datetime
  end

  def self.down
    remove_column :enterprise_groups, :logo_file_name
    remove_column :enterprise_groups, :logo_content_type
    remove_column :enterprise_groups, :logo_file_size
    remove_column :enterprise_groups, :logo_updated_at
  end
end
