class CreateCustomTabs < ActiveRecord::Migration[7.0]
  def change
    create_table :custom_tabs do |t|
      t.string :title
      t.text :content

      t.timestamps
    end
    add_reference :custom_tabs, :enterprise, foreign_key: { on_delete: :cascade }, index: true
  end
end
