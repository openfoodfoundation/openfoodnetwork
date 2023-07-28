class ChangeDefaultvalueForVisibleEnterprise < ActiveRecord::Migration[7.0]
  def up
    change_column :enterprises, :visible, :string, default: "only_through_links"
  end

  def down
    change_column :enterprises, :visible, :string, default: "public"
  end
end
