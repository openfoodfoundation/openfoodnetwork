class AddForeignKeyToReportRenderingOptionsUser < ActiveRecord::Migration[6.0]
  def change
    add_foreign_key :report_rendering_options, :spree_users, on_delete: :cascade
  end
end
