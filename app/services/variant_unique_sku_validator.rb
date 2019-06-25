class VariantUniqueSkuValidator
  attr_reader :variant

  def initialize(variant)
    @variant = variant
  end

  def validate_sku_uniqueness?
    !variant.is_master && !variant.deleted?
  end

  def validate_no_lookalikes_with_blank_sku
    return if variant.sku.present? || variant.product_id.blank?

    variants_with_blank_sku = lookalike_variants.where(sku: ["", nil])
    return if (variants_with_blank_sku - [variant]).blank?

    variant.errors.add(:sku, error_message_if_has_lookalike_with_same_sku_error)
  end

  private

  def error_message_if_has_lookalike_with_same_sku_error
    I18n.t("activerecord.errors.models.spree/variant.attributes.sku.has_lookalike_with_same_sku")
  end

  # Find variants that look like the current variant. This does not distinguish between "" and nil
  # in string attributes.
  def lookalike_variants
    variant.product.variants.where(lookalike_variants_conditions)
  end

  # Conditions for finding lookalike variants.
  def lookalike_variants_conditions
    { unit_value: variant.unit_value,
      unit_description: similar_string_attribute_value(variant.unit_description),
      display_name: similar_string_attribute_value(variant.display_name),
      display_as: similar_string_attribute_value(variant.display_as) }
  end

  # Use this to find similar values for a string attribute in the database. This is merely a helper
  # method for not distinguishing between "" and nil.
  def similar_string_attribute_value(value)
    value.presence || ["", nil]
  end
end
