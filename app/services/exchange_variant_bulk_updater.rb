# frozen_string_literal: true

class ExchangeVariantBulkUpdater
  def initialize(exchange)
    @exchange = exchange
  end

  def update!(variant_ids)
    sanitized_variant_ids = variant_ids.map(&:to_i).uniq
    existing_variant_ids = @exchange.variant_ids

    disassociate_variants!(existing_variant_ids - sanitized_variant_ids)
    associate_variants!(sanitized_variant_ids - existing_variant_ids)

    uncache_variant_associations
  end

  private

  def disassociate_variants!(variant_ids)
    return if variant_ids.blank?

    @exchange.exchange_variants.where(variant_id: variant_ids).delete_all
  end

  def associate_variants!(variant_ids)
    return if variant_ids.blank?

    new_exchange_variants = variant_ids.map do |variant_id|
      ExchangeVariant.new(exchange_id: @exchange.id, variant_id: variant_id)
    end
    ExchangeVariant.import!(new_exchange_variants)
  end

  def uncache_variant_associations
    @exchange.exchange_variants.reset
    @exchange.variants.proxy_association.reset
  end
end
