# frozen_string_literal: true

class EnableVariantTagsForEnterpriseWithInventoryButNotInUse < ActiveRecord::Migration[7.1]
  def up
    Flipper.enable_group(:variant_tag, :old_enterprise_with_no_inventory)
  end

  def down
    Flipper.disable_group(:variant_tag, :old_enterprise_with_no_inventory)
  end
end
