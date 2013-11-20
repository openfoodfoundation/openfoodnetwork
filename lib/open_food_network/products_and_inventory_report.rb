module OpenFoodNetwork

  class ProductsAndInventoryReport
    def initialize(user, params = {})
      @user = user
      @params = params
      #@variants = fetch_variants
      # Fetch filter(variants) + filter(master_variants)
      # Fetch master variants
      #
      # Filter variants
      #
      # Merge variants
      #
      # Build table
    end

    def header
      ["Supplier", "Product", "SKU", "Variant", "On Hand", "Price"]
    end

    def table
      variants.map do |variant|
        [variant.product.supplier.name,
         variant.product.name,
         variant.sku,
         variant.options_text,
         variant.count_on_hand,
         variant.price]
      end
    end

    def variants
      filter(child_variants) + filter(master_variants)
    end

    def child_variants
      Spree::Variant.where(:is_master => false)
      .joins(:product)
      .merge(Spree::Product.managed_by(@user))
    end
  end
end
