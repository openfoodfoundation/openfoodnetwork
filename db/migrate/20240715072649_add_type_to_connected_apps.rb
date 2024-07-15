class AddTypeToConnectedApps < ActiveRecord::Migration[7.0]
  def change
    add_column :connected_apps, :type, :string, default: "ConnectedApp", null: false
  end
end
