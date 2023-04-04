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

  def destroy_related_outgoing_variants(variant_id, order_cycle)
    internal_variants = ExchangeVariant.where(variant_id: variant_id).
      joins(:exchange).
      where(
        exchanges: { order_cycle: order_cycle, incoming: false }
      )
    internal_variants.destroy_all
  end

  private

  def only_variant_on_product?(variant)
    variant.product.variants == [variant]
  end
end
