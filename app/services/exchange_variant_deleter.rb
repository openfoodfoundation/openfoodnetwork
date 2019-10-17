class ExchangeVariantDeleter
  def delete(product)
    variant_ids = product.variants.map(&:id)
    ExchangeVariant.
      where(variant_id: variant_ids).
      delete_all
  end
end
