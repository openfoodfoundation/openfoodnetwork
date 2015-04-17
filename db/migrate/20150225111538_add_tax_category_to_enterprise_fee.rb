class AddTaxCategoryToEnterpriseFee < ActiveRecord::Migration
  def change
    add_column :enterprise_fees, :tax_category_id, :integer
    add_foreign_key :enterprise_fees, :spree_tax_categories, column: :tax_category_id
    add_index :enterprise_fees, :tax_category_id
  end
end
