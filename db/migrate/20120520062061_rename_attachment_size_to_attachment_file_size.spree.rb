# This migration comes from spree (originally 20120416233427)
class RenameAttachmentSizeToAttachmentFileSize < ActiveRecord::Migration
  def change
    rename_column :spree_assets, :attachment_size, :attachment_file_size
  end
end
