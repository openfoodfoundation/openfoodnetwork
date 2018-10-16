# Fixes variants whose product.variant_unit is 'weight' and miss a unit_value,
# showing 1 unit of the specified weight. That is, if the user chose Kg, it'll
# display 1 as unit.
class FixVariantsMissingUnitValue < ActiveRecord::Migration
  HUMAN_UNIT_VALUE = 1

  def up
    logger.info "Fixing variants missing unit_value...\n"

    variants_missing_unit_value.find_each do |variant|
      logger.info "Processing variant #{variant.id}..."

      fix_unit_value(variant)
    end

    logger.info "Done!"
  end

  def down
  end

  private

  def variants_missing_unit_value
    Spree::Variant
      .joins(:product)
      .readonly(false)
      .where(
        spree_products: { variant_unit: 'weight' },
        spree_variants: { unit_value: nil }
    )
  end

  def fix_unit_value(variant)
    variant.unit_value = HUMAN_UNIT_VALUE * variant.product.variant_unit_scale

    if variant.save
      logger.info "Successfully fixed variant #{variant.id}"
    else
      logger.info "Failed fixing variant #{variant.id}"
    end

    logger.info ""
  end

  def logger
    @logger ||= Logger.new('log/migrate.log')
  end
end
