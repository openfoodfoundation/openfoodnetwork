class CreateEnterpriseFees < ActiveRecord::Migration
  def change
    create_table :enterprise_fees do |t|
      t.references :enterprise
      t.string :fee_type
      t.string :name

      t.timestamps
    end
  end
end
