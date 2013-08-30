class CreateAdjustmentMetadata < ActiveRecord::Migration
  def change
    create_table :adjustment_metadata do |t|
      t.integer :adjustment_id
      t.integer :enterprise_id
      t.string :fee_name
      t.string :fee_type
      t.string :enterprise_role
    end

    add_index :adjustment_metadata, :adjustment_id
  end
end
