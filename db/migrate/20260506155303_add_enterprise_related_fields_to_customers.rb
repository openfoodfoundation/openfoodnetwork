# frozen_string_literal: true

class AddEnterpriseRelatedFieldsToCustomers < ActiveRecord::Migration[7.1]
  def change
    create_enum :customer_types, %w[individual enterprise]

    change_table :customers, bulk: true do |t|
      t.enum :customer_type, enum_type: :customer_types, default: "individual", null: false
      t.string :enterprise_name
      t.string :enterprise_acn
      t.boolean :enterprise_charges_sales_tax, default: false, null: false
    end
  end
end
