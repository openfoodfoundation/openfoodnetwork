# frozen_string_literal: true

# Only new line items snapshot their variant display name. Existing rows keep a
# NULL value and fall back to the live variant display name and product name,
# matching how product_name and variant_name already behave. A backfill would
# freeze whatever names happen to be live at deploy time, including edits made
# before this feature shipped, and cannot recover the names originally ordered.
class AddVariantDisplayNameToLineItems < ActiveRecord::Migration[7.2]
  def change
    add_column :spree_line_items, :variant_display_name, :string
  end
end
