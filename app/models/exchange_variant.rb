# frozen_string_literal: true

class ExchangeVariant < ApplicationRecord
  belongs_to :exchange
  belongs_to :variant, class_name: 'Spree::Variant'
  after_destroy :destroy_related_outgoing_variants

  def destroy_related_outgoing_variants
    VariantDeleter.new.destroy_related_outgoing_variants(variant_id, exchange.order_cycle)
  end
end
