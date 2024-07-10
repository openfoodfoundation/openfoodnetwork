class EnableFeatureAdminStyleV3ForAdmins < ActiveRecord::Migration[7.0]
  def up
    Flipper.enable_group(:admin_style_v3, :admins)
  end
end
