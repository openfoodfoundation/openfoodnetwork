class MigrateVariantUnitValues < ActiveRecord::Migration
  def up
    Spree::Variant.all.select { |v|
      v.unit_value.nil? && v.product&.variant_unit == "items"
    }.each do |variant|
      variant.unit_value = 1
      variant.save
    end
  end

  def down
  end
end
