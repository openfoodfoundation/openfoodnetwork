module Spree
  ProductsHelper.class_eval do
    # Return the price of the variant, or nil if it is identical to the master price
    def variant_price_diff(variant)
      return nil if variant.price == variant.product.price
      "(#{number_to_currency variant.price})"
    end
  end
end
