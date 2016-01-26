class AddEnableResetToVariantOverrides < ActiveRecord::Migration
  def change
    add_column :variant_overrides, :enable_reset, :boolean
  end
end
