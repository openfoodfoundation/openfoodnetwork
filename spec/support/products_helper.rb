module OpenFoodNetwork
  module ProductsHelper
    def with_products_require_tax_category(value)
      original_value = Spree::Config.products_require_tax_category

      Spree::Config.products_require_tax_category = value
      yield
    ensure
      Spree::Config.products_require_tax_category = original_value
    end
  end
end
