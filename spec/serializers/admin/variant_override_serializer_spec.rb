describe Api::Admin::VariantOverrideSerializer do
  let(:variant) { create(:variant) }
  let(:hub) { create(:distributor_enterprise) }
  let(:price) { 77.77 }
  let(:count_on_hand) { 11111 }
  let(:variant_override) { create(:variant_override, variant: variant, hub: hub, price: price, count_on_hand: count_on_hand) }

  it "serializes a variant override" do
    serializer = Api::Admin::VariantOverrideSerializer.new variant_override
    serializer.to_json.should match variant.id.to_s
    serializer.to_json.should match hub.id.to_s
    serializer.to_json.should match price.to_s
    serializer.to_json.should match count_on_hand.to_s
  end
end
