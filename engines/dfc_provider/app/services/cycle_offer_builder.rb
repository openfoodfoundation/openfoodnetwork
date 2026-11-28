# frozen_string_literal: true

# The offer of a variant in one order cycle: the price that a buyer pays in
# that cycle, which is the variant price with the distributor's price override
# and the enterprise fees of the cycle.
#
# The override index and the enterprise fee calculator are built once, so that
# a sale session with many offers doesn't query them again for every variant.
class CycleOfferBuilder
  def initialize(distributor, order_cycle)
    @variant_scoper = OpenFoodNetwork::ScopeVariantToHub.new(distributor)
    @enterprise_fee_calculator = OpenFoodNetwork::EnterpriseFeeCalculator.new(
      distributor, order_cycle
    )
  end

  # An offer belongs to one sale session, so its id is nested under the session
  # like the lines of an order are nested under the order.
  def build(variant, session_id)
    # The supplied product links to the producer's own offer, so it has to be
    # built before we scope the variant to this shop's price and stock.
    supplied_product = SuppliedProductBuilder.supplied_product(variant)

    @variant_scoper.scope(variant)

    DataFoodConsortium::ConnectorV1::Offer.new(
      "#{session_id}/offers/#{variant.id}",
      price: DataFoodConsortium::ConnectorV1::Price.new(
        value: price(variant).to_f,
        unit: OfferBuilder.price_measure(variant)&.semanticId,
      ),
      stockLimitation: DfcBuilder.stock_limitation(variant),
      offeredItem: supplied_product,
    )
  end

  private

  # The price shown in the shop: the variant price, which the distributor's
  # override can replace, plus the per-item enterprise fees of the cycle.
  # Fees per order and shipping fees are not part of a unit price.
  def price(variant)
    variant.price + @enterprise_fee_calculator.indexed_fees_for(variant)
  end
end
