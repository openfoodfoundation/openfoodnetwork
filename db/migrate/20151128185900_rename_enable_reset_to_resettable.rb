class RenameEnableResetToResettable < ActiveRecord::Migration
	rename_column :variant_overrides, :enable_reset, :resettable
end
