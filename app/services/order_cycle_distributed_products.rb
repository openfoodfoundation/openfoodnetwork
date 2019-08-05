# Finds valid products distributed by a particular distributor in an order cycle
#
# If a product without variants is added to an order cycle, and then some
# variants are added to that product, but not the order cycle, then the master
# variant should not available for customers to purchase. This class filters
# out such products so that the customer cannot purchase them.
class OrderCycleDistributedProducts
  def initialize(order_cycle, distributor)
    @order_cycle = order_cycle
    @distributor = distributor
  end

  # Returns an ActiveRecord relation without invalid products. Check
  # #valid_products_distributed_by for details
  #
  # @return [ActiveRecord::Relation<Spree::Product>]
  def relation
    products = Spree::Product
      .joins(:variants_including_master)
      .merge(order_cycle.variants_distributed_by(distributor))

    variants = order_cycle.variants_distributed_by(distributor)

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
  def product_has_only_obsolete_master_in_distribution?(product, distributed_variants)
    product.has_variants? &&
      distributed_variants_include_master?(product) &&
      distributed_current_variants(product).empty?
  end

  def distributed_variants_include_master?(product)
    order_cycle
      .variants_distributed_by(distributor)
      .exists?(product.master.id)
  end

  # Returns the product variants that are currently under distribution, aka.
  # are present in a exchange
  #
  # ActiveRecord::Relation<Spree::Variant>
  def distributed_current_variants(product)
    order_cycle
      .variants_distributed_by(distributor)
      .where(id: product.variants)
  end
end
