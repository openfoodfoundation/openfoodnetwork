# frozen_string_literal: true

class ExchangeVariantDeleter
  def delete(variant)
    ExchangeVariant.where(variant_id: variant.id).delete_all
  end
end
