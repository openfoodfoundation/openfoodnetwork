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
    product_ids = valid_products.map(&:id)
    Spree::Product.where(id: product_ids)
  end

  def valid_products
    Spree::Product
      .joins(variants: { exchange_variants: :exchange })
      .merge(distributor.inventory_variants)
      .merge(Exchange.in_order_cycle(order_cycle))
      .merge(Exchange.outgoing)
      .merge(Exchange.to_enterprise(distributor))
  end

  private

  attr_reader :order_cycle, :distributor
end
