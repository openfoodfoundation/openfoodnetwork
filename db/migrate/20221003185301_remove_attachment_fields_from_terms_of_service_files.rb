class RemoveAttachmentFieldsFromTermsOfServiceFiles < ActiveRecord::Migration[6.1]
  def change
    remove_column :terms_of_service_files, :attachment_file_name, :string
    remove_column :terms_of_service_files, :attachment_content_type, :string
    remove_column :terms_of_service_files, :attachment_file_size, :integer
    remove_column :terms_of_service_files, :attachment_updated_at, :datetime
  end
end
