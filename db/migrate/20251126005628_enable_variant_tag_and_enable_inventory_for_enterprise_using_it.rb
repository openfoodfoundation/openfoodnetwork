# frozen_string_literal: true

class EnableVariantTagAndEnableInventoryForEnterpriseUsingIt < ActiveRecord::Migration[7.1]
  def up
    Flipper.disable_group(:variant_tag, "enterprise_created_after_2025_08_11")
    Flipper.disable_group(:variant_tag, "old_enterprise_with_no_inventory")

    Flipper.enable_group(:variant_tag, "enterprise_with_no_inventory")

    Flipper.disable_group(:inventory, "enterprise_created_before_2025_08_11")

    Flipper.enable_group(:inventory, "enterprise_with_inventory")
  end

  def down
    Flipper.enable_group(:variant_tag, "enterprise_created_after_2025_08_11")
    Flipper.enable_group(:variant_tag, "old_enterprise_with_no_inventory")

    Flipper.disable_group(:variant_tag, "enterprise_with_no_inventory")

    Flipper.enable_group(:inventory, "enterprise_created_before_2025_08_11")

    Flipper.disable_group(:inventory, "enterprise_with_inventory")
  end
end
