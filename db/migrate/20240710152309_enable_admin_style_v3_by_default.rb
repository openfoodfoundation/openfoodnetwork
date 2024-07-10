class EnableAdminStyleV3ByDefault < ActiveRecord::Migration[7.0]
  def change
    Flipper.enable(:admin_style_v3)
  end
end
