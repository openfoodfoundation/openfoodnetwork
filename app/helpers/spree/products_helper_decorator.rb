module Spree
  ProductsHelper.class_eval do
    # Return the price of the variant
    def variant_price_diff(variant)
      "(#{Spree::Money.new(variant.price).to_s})"
    end


    def product_has_variant_unit_option_type?(product)
      product.option_types.any? { |option_type| variant_unit_option_type? option_type }
    end


    def variant_unit_option_type?(option_type)
      Spree::Product.all_variant_unit_option_types.include? option_type
    end


    def product_variant_unit_options
      [['Weight', 'weight'],
       ['Volume', 'volume'],
       ['Items', 'items']]
    end
  end
end
