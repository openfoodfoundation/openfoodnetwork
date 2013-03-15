module OpenFoodWeb

  # The concern of separating products by distributor and order cycle is dealt with in a few
  # other places: OpenFoodWeb::Searcher (for searching over products) and in
  # Spree::BaseHelper decorator (for taxon counts).

  module SplitProductsByDistributor
    # If a distributor is provided, split the list of products into local (at that
    # distributor) and remote (at another distributor). If a distributor is not
    # provided, perform no split.
    def split_products_by_distributor(products, distributor)
      products_local = products_remote = nil

      if distributor
        products_local = products.select { |p| p.distributors.include? distributor }
        products_remote = products.reject { |p| p.distributors.include? distributor }
        products = nil
      end

      [products, products_local, products_remote]
    end
  end
end
