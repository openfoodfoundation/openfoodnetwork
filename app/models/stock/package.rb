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
