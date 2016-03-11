class AddInheritsTaxCategoryToEnterpriseFees < ActiveRecord::Migration
  def change
    add_column :enterprise_fees, :inherits_tax_category, :boolean, null: false, default: false
  end
end
