describe Api::ProductSerializer do
  let(:hub) { create(:distributor_enterprise) }
  let(:oc) { create(:simple_order_cycle, distributors: [hub], variants: [v1]) }
  let(:p) { create(:simple_product) }
  let!(:v1) { create(:variant, product: p, unit_value: 3) }
  let!(:v2) { create(:variant, product: p, unit_value: 5) }

  it "scopes variants to distribution" do
    s = Api::ProductSerializer.new p, current_distributor: hub, current_order_cycle: oc
    json = s.to_json
    json.should     include v1.options_text
    json.should_not include v2.options_text
  end
end
