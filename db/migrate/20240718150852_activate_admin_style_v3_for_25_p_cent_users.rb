class ActivateAdminStyleV3For25PCentUsers < ActiveRecord::Migration[7.0]
  def up
    Flipper.enable_percentage_of_actors(:admin_style_v3, 25)
  end
end
