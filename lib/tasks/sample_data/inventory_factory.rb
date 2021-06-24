# frozen_string_literal: true

require "tasks/sample_data/logging"

module SampleData
  class InventoryFactory
    include Logging

    def create_samples(products)
      log "Creating inventories"
      marys_shop = Enterprise.find_by(name: "Mary's Online Shop")
      products.each do |product|
        create_item(marys_shop, product)
      end
    end

    private

    def create_item(shop, product)
      InventoryItem.create_with(
        enterprise: shop,
        variant: product.variants.first,
        visible: true
      ).find_or_create_by!(variant_id: product.variants.first.id)
      create_override(shop, product)
    end

    def create_override(shop, product)
      VariantOverride.create_with(
        variant: product.variants.first,
        hub: shop,
        price: 12,
        on_demand: false,
        count_on_hand: 5
      ).find_or_create_by!(variant_id: product.variants.first.id)
    end
  end
end
