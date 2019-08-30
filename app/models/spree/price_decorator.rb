module Spree
  Price.class_eval do
    acts_as_paranoid without_default_scope: true

    after_save :refresh_products_cache

    # Allow prices to access associated soft-deleted variants.
    def variant
      Spree::Variant.unscoped { super }
    end

    private

    def refresh_products_cache
      variant.andand.refresh_products_cache
    end
  end
end
