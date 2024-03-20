# frozen_string_literal: true

class BackorderJob < ApplicationJob
  queue_as :default

  def self.check_stock(order)
    variants_needing_stock = order.variants.select do |variant|
      # TODO: scope variants to hub.
      # We are only supporting producer stock at the moment.
      variant.on_hand&.negative?
    end

    linked_variants = variants_needing_stock.select do |variant|
      variant.semantic_links.present?
    end

    linked_variants.each do |variant|
      # needed_quantity = -1 * variant.on_hand
      # create DFC Order
      # post order to endpoint
    end
  end

  def perform(*args)
    # Do something later
  end
end
