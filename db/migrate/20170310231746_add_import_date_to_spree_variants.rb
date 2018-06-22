class AddImportDateToSpreeVariants < ActiveRecord::Migration
  def change
    add_column :spree_variants, :import_date, :datetime
  end
end
