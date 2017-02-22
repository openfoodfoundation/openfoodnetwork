require 'open_food_network/products_cache'

module Spree
  Preference.class_eval do
    after_save :refresh_products_cache

    # When the setting preferred_product_selection_from_inventory_only has changed, we want to
    # refresh all active exchanges for this enterprise.
    def refresh_products_cache
      if product_selection_from_inventory_only_changed?
        OpenFoodNetwork::ProductsCache.distributor_changed(enterprise)
      end
    end


    private

    def product_selection_from_inventory_only_changed?
      !!(key =~ product_selection_from_inventory_only_regex)
    end

    def enterprise
      enterprise_id = key.match(product_selection_from_inventory_only_regex)[1]
      Enterprise.find(enterprise_id)
    end

    def product_selection_from_inventory_only_regex
      /^enterprise\/product_selection_from_inventory_only\/(\d+)$/
    end
  end
end
