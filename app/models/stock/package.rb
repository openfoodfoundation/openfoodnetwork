# Extends Spree's Package implementation to skip shipping methods that are not
# valid for OFN.
#
# It requires the following configuration in config/initializers/spree.rb:
#
#   Spree.config do |config|
#     ...
#     config.package_factory = Stock::Package
#   end
#
module Stock
  class Package < Spree::Stock::Package
    # Returns all existing shipping categories.
    #   It does not filter by the shipping categories of the products in the order.
    #   It allows checkout of products with categories that are not the shipping methods categories
    #   It disables the matching of product shipping category with shipping method's category
    #
    # @return [Array<Spree::ShippingCategory>]
    def shipping_categories
      Spree::ShippingCategory.all
    end

    # Skips the methods that are not used by the order's distributor
    #
    # @return [Array<Spree::ShippingMethod>]
    def shipping_methods
      super.delete_if do |shipping_method|
        !ships_with?(order.distributor, shipping_method)
      end
    end

    private

    # Checks whether the given distributor provides the specified shipping method
    #
    # @param distributor [Spree::Enterprise]
    # @param shipping_method [Spree::ShippingMethod]
    # @return [Boolean]
    def ships_with?(distributor, shipping_method)
      distributor.shipping_methods.include?(shipping_method)
    end
  end
end
