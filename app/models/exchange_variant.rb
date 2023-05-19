# frozen_string_literal: true

class ExchangeVariant < ApplicationRecord
  belongs_to :exchange
  belongs_to :variant, class_name: 'Spree::Variant'

  after_destroy :delete_related_outgoing_variants

  def delete_related_outgoing_variants
    ExchangeVariant.where(variant_id: variant_id).
      joins(:exchange).
      where(exchanges: { order_cycle: exchange.order_cycle, incoming: false }).
      delete_all
  end
end
