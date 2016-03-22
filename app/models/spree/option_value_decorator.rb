module Spree
  OptionValue.class_eval do
    after_save :refresh_products_cache
    around_destroy :refresh_products_cache_from_destroy


    private

    def refresh_products_cache
      variants(:reload).each &:refresh_products_cache
    end

    def refresh_products_cache_from_destroy
      vs = variants(:reload).to_a
      yield
      vs.each &:refresh_products_cache
    end

  end
end
