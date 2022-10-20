class RemoveLogoFieldsFromEnterprise < ActiveRecord::Migration[6.1]
  def change
    remove_column :enterprises, :logo_file_name, :string
    remove_column :enterprises, :logo_content_type, :string
    remove_column :enterprises, :logo_file_size, :integer
    remove_column :enterprises, :logo_updated_at, :datetime
  end
end
