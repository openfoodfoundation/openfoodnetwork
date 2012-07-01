module Spree
  ProductsHelper.class_eval do
    # Return the price of the variant
    def variant_price_diff(variant)
      "(#{number_to_currency variant.price})"
    end
  end
end
