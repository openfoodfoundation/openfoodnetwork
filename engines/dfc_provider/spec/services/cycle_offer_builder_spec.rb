# frozen_string_literal: true

require_relative "../spec_helper"

RSpec.describe CycleOfferBuilder do
  let(:producer) { create(:supplier_enterprise, name: "Producer") }
  let(:coordinator) { create(:distributor_enterprise, name: "Coordinator") }
  let(:hub) { create(:distributor_enterprise, name: "Hub") }
  let(:variant) { create(:variant, enterprise: producer, price: 10) }
  let(:order_cycle) { create(:open_order_cycle, coordinator:) }
  let(:session_id) { "http://test.host/api/dfc/enterprises/#{hub.id}/sale_sessions/1" }

  let!(:incoming_exchange) {
    create(:exchange, order_cycle:, sender: producer, receiver: coordinator, incoming: true,
                      variants: [variant])
  }

  subject(:offer) { described_class.new(hub, order_cycle).build(variant, session_id) }

  it "nests the offer id under its sale session" do
    expect(offer.semanticId).to eq "#{session_id}/offers/#{variant.id}"
  end

  it "offers the supplied product of the variant that the catalog lists" do
    expect(offer.offeredItem.semanticId).to eq(
      SuppliedProductBuilder.supplied_product(variant).semanticId
    )
  end

  context "with inventory enabled", feature: :inventory do
    before { create(:variant_override, hub:, variant:, price: 20) }

    it "prices the offer with the price the distributor overrides" do
      expect(offer.price.value).to eq 20
    end

    # The supplied product lists the producer's own offer. It must not carry
    # the price of this shop.
    it "keeps the producer's price in the supplied product" do
      producer_offer = offer.offeredItem.catalogItems.first.offers.first

      expect(producer_offer.price.value).to eq 10
    end
  end
end
