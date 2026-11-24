# frozen_string_literal: true

# Snapshot the variant's display_as override on new line items so that later
# catalogue edits don't change the unit shown on existing orders. Existing rows
# keep a NULL value and fall back to the live variant value.
class AddVariantDisplayAsToLineItems < ActiveRecord::Migration[7.2]
  def change
    add_column :spree_line_items, :variant_display_as, :string
  end
end
