class RemovePromoImageFieldsFromEnterpriseGroup < ActiveRecord::Migration[6.1]
  def change
    remove_column :enterprise_groups, :promo_image_file_name, :string
    remove_column :enterprise_groups, :promo_image_content_type, :string
    remove_column :enterprise_groups, :promo_image_file_size, :integer
    remove_column :enterprise_groups, :promo_image_updated_at, :datetime
  end
end
