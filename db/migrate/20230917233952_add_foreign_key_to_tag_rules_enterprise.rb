class AddForeignKeyToTagRulesEnterprise < ActiveRecord::Migration[6.0]
  def change
    add_foreign_key :tag_rules, :enterprises, on_delete: :cascade
  end
end
