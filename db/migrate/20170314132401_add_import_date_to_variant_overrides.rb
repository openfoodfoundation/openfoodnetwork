class AddImportDateToVariantOverrides < ActiveRecord::Migration
  def change
    add_column :variant_overrides, :import_date, :datetime
  end
end
