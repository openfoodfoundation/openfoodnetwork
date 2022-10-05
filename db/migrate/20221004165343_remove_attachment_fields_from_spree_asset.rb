class RemoveAttachmentFieldsFromSpreeAsset < ActiveRecord::Migration[6.1]
  def change
    remove_column :spree_assets, :attachment_file_name, :string
    remove_column :spree_assets, :attachment_content_type, :string
    remove_column :spree_assets, :attachment_file_size, :integer
    remove_column :spree_assets, :attachment_updated_at, :datetime
  end
end

