class AddForeignKeyToTagRulesEnterprises < ActiveRecord::Migration[6.0]
  def change
    add_foreign_key :tag_rules, :enterprises, column: :enterprise_id
  end
end
