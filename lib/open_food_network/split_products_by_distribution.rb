module OpenFoodWeb

  # The concern of separating products by distributor and order cycle is dealt with in a few
  # other places: OpenFoodWeb::Searcher (for searching over products) and in
  # Spree::BaseHelper decorator (for taxon counts).

  module SplitProductsByDistribution
    # If a distributor or order cycle is provided, split the list of products into local (at that
    # distributor/order cycle) and remote (available elsewhere). If a distributor is not
    # provided, perform no split.
    def split_products_by_distribution(products, distributor, order_cycle)
      products_local = products_remote = nil

      if distributor || order_cycle
        selector = proc do |product|
          (!distributor || product.in_distributor?(distributor)) && (!order_cycle || product.in_order_cycle?(order_cycle))
        end

        products_local = products.select &selector
        products_remote = products.reject &selector
        products = nil
      end

      [products, products_local, products_remote]
    end
  end
end
