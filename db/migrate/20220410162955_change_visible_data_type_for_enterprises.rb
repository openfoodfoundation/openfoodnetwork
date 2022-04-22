class ChangeVisibleDataTypeForEnterprises < ActiveRecord::Migration[6.1]
  class Enterprise < ActiveRecord::Base; end
  def up
    add_column :enterprises, :visible_tmp, :string, limit: 255, default: "public", null: false
    Enterprise.reset_column_information

    Enterprise.where(:visible => 0).update_all(visible_tmp: "only_through_links")
    remove_column :enterprises, :visible
    rename_column :enterprises, :visible_tmp, :visible
  end

  def down
    add_column :enterprises, :visible_tmp, :boolean,  default: true, null: false
    Enterprise.reset_column_information

    Enterprise.where("visible != 'public'").update_all(visible_tmp: false)
    remove_column :enterprises, :visible
    rename_column :enterprises, :visible_tmp, :visible
  end
end
