# frozen_string_literal: true

class CopySupplierToEnterpriseInSpreeVariants < ActiveRecord::Migration[7.1]
  def up
    execute <<~SQL.squish
      UPDATE spree_variants
      SET enterprise_id = supplier_id
      WHERE supplier_id IS NOT NULL AND enterprise_id IS NULL
    SQL
  end

  def down
    # No down migration needed
  end
end
