# frozen_string_literal: true

class RemoveExistingVariantImages < ActiveRecord::Migration[7.2]
  class SpreeImage < ActiveRecord::Base
    self.table_name = "spree_assets"
    self.inheritance_column = :_type_disabled
  end

  def up
    SpreeImage.where(viewable_type: "Spree::Variant").delete_all
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
