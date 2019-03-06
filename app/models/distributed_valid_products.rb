# Finds valid products distributed by a particular distributor in an order cycle
class DistributedValidProducts
  def initialize(order_cycle, distributor)
    @order_cycle = order_cycle
    @distributor = distributor
  end

  def all
    variants = order_cycle.variants_distributed_by(distributor)
    products = variants.map(&:product).uniq

    valid_products = products.reject do |product|
      product_has_only_obsolete_master_in_distribution?(product, variants)
    end
    product_ids = valid_products.map(&:id)

    Spree::Product.where(id: product_ids)
  end

  private

  attr_reader :order_cycle, :distributor

  # If a product without variants is added to an order cycle, and then some variants are added
  # to that product, but not the order cycle, then the master variant should not available for
  # customers to purchase.
  #
  # This method is used by #valid_products_distributed_by to filter out such products so that
  # the customer cannot purchase them.
  def product_has_only_obsolete_master_in_distribution?(product, distributed_variants)
    product.has_variants? &&
      distributed_variants.include?(product.master) &&
      (product.variants & distributed_variants).empty?
  end
end
