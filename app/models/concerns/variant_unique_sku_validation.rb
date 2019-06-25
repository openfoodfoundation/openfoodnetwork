# This adds validation to require SKU to be unique among the non-master and not deleted variants of
# the same product. Additionally, there can be at most one variant with blank SKU for a products
# variants with the same unit_value, unit_description, display_name, and display_as.
#
# Master and deleted variants are ignored.

module VariantUniqueSkuValidation
  extend ActiveSupport::Concern

  included do
    # Including is_master and deleted_at in the uniqueness scope is a workaround to ignore master
    # and deleted variants.
    #
    # Handle validation for blank SKU separately.
    validates :sku, uniqueness: { scope: [:product_id, :is_master, :deleted_at], allow_blank: true,
                                  if: :validate_sku_uniqueness? }

    # When SKU is blank, make sure that there is no other variant that looks similar which also has
    # blank SKU.
    validate :validate_no_lookalikes_with_blank_sku, if: :validate_sku_uniqueness?
  end

  def variant_unique_sku_validator
    @variant_unique_sku_validator ||= VariantUniqueSkuValidator.new(self)
  end

  delegate :validate_sku_uniqueness?, to: :variant_unique_sku_validator
  delegate :validate_no_lookalikes_with_blank_sku, to: :variant_unique_sku_validator
end
