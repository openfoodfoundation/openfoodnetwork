# Orphaned records can be found before running this migration with the following SQL:

# SELECT COUNT(*)
# FROM tag_rules
# LEFT JOIN enterprises
#   ON tag_rules.enterprise_id = enterprises.id
# WHERE enterprises.id IS NULL
#   AND tag_rules.enterprise_id IS NOT NULL


class AddForeignKeyToTagRulesEnterprises < ActiveRecord::Migration[6.0]
  def change
    add_foreign_key :tag_rules, :enterprises, column: :enterprise_id
  end
end
