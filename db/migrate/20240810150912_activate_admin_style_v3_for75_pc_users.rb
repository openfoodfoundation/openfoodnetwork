class ActivateAdminStyleV3For75PcUsers < ActiveRecord::Migration[7.0]
  def up
    Flipper.enable_percentage_of_actors(:admin_style_v3, 75)
  end

  def down
    Flipper.enable_percentage_of_actors(:admin_style_v3, 50)
  end
end
