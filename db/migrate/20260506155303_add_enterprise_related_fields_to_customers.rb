class AddEnterpriseRelatedFieldsToCustomers < ActiveRecord::Migration[7.1]
  def change
    add_column :customers, :customer_type, :string,
               limit: 32, null: false, default: 'individual'
    add_column :customers, :enterprise_name, :string, limit: 128
    add_column :customers, :enterprise_acn, :string, limit: 64
    add_column :customers, :enterprise_charges_sales_tax, :boolean,
               default: false, null: false
  end
end
