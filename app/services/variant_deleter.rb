# frozen_string_literal: true

# Checks the validity of a soft-delete call.
class VariantDeleter
  def delete(variant)
    if only_variant_on_product?(variant)
      variant.errors.add :product, I18n.t(:spree_variant_product_error)
      return false
    end

    variant.destroy
  end

  private

  def only_variant_on_product?(variant)
    variant.product.variants == [variant]
  end
end
