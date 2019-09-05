module Spree
  Price.class_eval do
    after_save :refresh_products_cache

    private

    def check_price
      if currency.nil?
        self.currency = Spree::Config[:currency]
      end
    end

    def refresh_products_cache
      variant.andand.refresh_products_cache
    end
  end
end
