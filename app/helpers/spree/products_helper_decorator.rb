module Spree
  ProductsHelper.class_eval do
    # Return the price of the variant
    def variant_price_diff(variant)
      "(#{number_to_currency variant.price})"
    end


    def variant_unit_option_type?(option_type)
      Spree::Product.all_variant_unit_option_types.include? option_type
    end
  end
end
