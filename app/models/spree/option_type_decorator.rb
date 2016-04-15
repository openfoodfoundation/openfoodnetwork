module Spree
  OptionType.class_eval do
    has_many :products, through: :product_option_types
    after_save :refresh_products_cache


    private

    def refresh_products_cache
      products(:reload).each &:refresh_products_cache
    end
  end
end
