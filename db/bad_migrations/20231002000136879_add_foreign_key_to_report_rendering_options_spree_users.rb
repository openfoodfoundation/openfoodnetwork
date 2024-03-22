# Orphaned records can be found before running this migration with the following SQL:

# SELECT COUNT(*)
# FROM report_rendering_options
# LEFT JOIN spree_users
#   ON report_rendering_options.user_id = spree_users.id
# WHERE spree_users.id IS NULL
#   AND report_rendering_options.user_id IS NOT NULL


class AddForeignKeyToReportRenderingOptionsSpreeUsers < ActiveRecord::Migration[6.0]
  def change
    add_foreign_key :report_rendering_options, :spree_users, column: :user_id
  end
end
