class AddRequireLoginToEnterprise < ActiveRecord::Migration
  def change
    add_column :enterprises, :require_login, :boolean, default: false, null: false
  end
end
