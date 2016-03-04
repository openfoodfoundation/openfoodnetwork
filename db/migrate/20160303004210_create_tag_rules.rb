class CreateTagRules < ActiveRecord::Migration
  def change
    create_table :tag_rules do |t|
      t.references :enterprise, null: false, index: true
      t.string :type, null: false

      t.timestamps
    end
  end
end
