describe Api::Admin::ExchangeSerializer do
  let(:v1) { create(:variant) }
  let(:v2) { create(:variant) }
  let(:exchange) { create(:exchange, incoming: false, variants: [v1, v2]) }
  let(:permissions_mock) { double(:permissions) }
  let(:serializer) { Api::Admin::ExchangeSerializer.new exchange }


  before do
    allow(OpenFoodNetwork::Permissions).to receive(:new) { permissions_mock }
    allow(permissions_mock).to receive(:visible_variants_for_outgoing_exchanges_between) do
      # This is the permitted list of variants
      Spree::Variant.where(id: [v1] )
    end
  end

  it "filters variants within the exchange based on permissions" do
    visible_variants = serializer.variants
    expect(permissions_mock).to have_received(:visible_variants_for_outgoing_exchanges_between).
    with(exchange.sender, exchange.receiver, order_cycle: exchange.order_cycle)
    expect(exchange.variants).to include v1, v2
    expect(visible_variants.keys).to include v1.id
    expect(visible_variants.keys).to_not include v2.id
  end
end
