module Spree
  BaseHelper.class_eval do
    def taxons_tree(root_taxon, current_taxon, max_level = 1)
      return '' if max_level < 1 || root_taxon.children.empty?
      content_tag :ul, :class => 'taxons-list' do
        root_taxon.children.map do |taxon|
          css_class = (current_taxon && current_taxon.self_and_ancestors.include?(taxon)) ? 'current' : nil

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
