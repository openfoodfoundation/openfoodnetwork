class CreateColumnPreferences < ActiveRecord::Migration
  def change
    create_table :column_preferences do |t|
      t.references :user, null: false, index: true
      t.string :action_name, null: false, index: true
      t.string :column_name, null: false
      t.boolean :visible, null: false

      t.timestamps
    end
    add_index :column_preferences, [:user_id, :action_name, :column_name], unique: true, name: 'index_column_prefs_on_user_id_and_action_name_and_column_name'
  end
end
