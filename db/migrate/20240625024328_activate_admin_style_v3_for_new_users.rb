class ActivateAdminStyleV3ForNewUsers < ActiveRecord::Migration[7.0]
  def up
    Flipper.enable_group(:admin_style_v3, :new_2024_07_03)
  end
end
