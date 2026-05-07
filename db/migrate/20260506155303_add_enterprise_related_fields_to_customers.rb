# frozen_string_literal: true

class AddEnterpriseRelatedFieldsToCustomers < ActiveRecord::Migration[7.1]
  def change
    change_table :customers, bulk: true do |t|
      t.string :customer_type, default: "individual", null: false
      t.string :enterprise_name
      t.string :enterprise_acn
      t.boolean :enterprise_charges_sales_tax, default: false, null: false
    end
  end
end
