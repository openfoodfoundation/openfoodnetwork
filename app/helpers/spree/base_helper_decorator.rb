module Spree
  BaseHelper.class_eval do
    
    # TODO can we delete this?
    # Spree code we are overriding to render sidebar
    # No longer rendering sidebar
    def taxons_tree(root_taxon, current_taxon, max_level = 1)
      return '' if max_level < 1 || root_taxon.children.empty?
      content_tag :ul, :class => 'taxons-list' do
        root_taxon.children.map do |taxon|
          css_class = (current_taxon && current_taxon.self_and_ancestors.include?(taxon)) ? 'current' : nil

          # The concern of separating products by distributor and order cycle is dealt with in
          # a few other places: OpenFoodNetwork::Searcher (for searching over products) and in
          # OpenFoodNetwork::SplitProductsByDistribution (for splitting the main product display).

          products = Product.in_taxon(taxon)
          products = products.in_distributor(current_distributor) if current_distributor
          products = products.in_order_cycle(current_order_cycle) if current_order_cycle
          num_products = products.count

          content_tag :li, :class => css_class do
           link_to(taxon.name, seo_url(taxon)) +
              " (#{num_products})" +
              taxons_tree(taxon, current_taxon, max_level - 1)
          end
        end.join("\n").html_safe
      end
    end

  end
end
