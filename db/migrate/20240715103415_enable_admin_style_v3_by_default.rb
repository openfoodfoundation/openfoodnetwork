class EnableAdminStyleV3ByDefault < ActiveRecord::Migration[7.0]
  def up
    Flipper.enable(:admin_style_v3)
  end
end
