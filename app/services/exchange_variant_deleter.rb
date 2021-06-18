# frozen_string_literal: true

class ExchangeVariantDeleter
  def delete(product)
    ExchangeVariant.
      where(variant_id: product.variants.select(:id)).
      delete_all
  end
end
