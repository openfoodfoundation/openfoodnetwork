class AddAllowOrderChangesToEnterprise < ActiveRecord::Migration
  def change
    add_column :enterprises, :allow_order_changes, :boolean, default: false, null: false
  end
end
