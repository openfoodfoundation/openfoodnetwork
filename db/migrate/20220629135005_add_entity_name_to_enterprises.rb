class AddEntityNameToEnterprises < ActiveRecord::Migration[6.1]
  def change
    add_column :enterprises, :entity_name, :string
  end
end
