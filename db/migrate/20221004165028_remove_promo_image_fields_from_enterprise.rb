class RemovePromoImageFieldsFromEnterprise < ActiveRecord::Migration[6.1]
  def change
    remove_column :enterprises, :promo_image_file_name, :string
    remove_column :enterprises, :promo_image_content_type, :string
    remove_column :enterprises, :promo_image_file_size, :integer
    remove_column :enterprises, :promo_image_updated_at, :datetime
  end
end
