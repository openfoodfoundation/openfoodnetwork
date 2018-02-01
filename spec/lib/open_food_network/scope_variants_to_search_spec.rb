require 'open_food_network/scope_variants_for_search'

describe OpenFoodNetwork::ScopeVariantsForSearch do
  let!(:p1) { create(:simple_product, name: 'Product 1') }
  let!(:p2) { create(:simple_product, sku: 'Product 1a') }
  let!(:p3) { create(:simple_product, name: 'Product 3') }
  let!(:p4) { create(:simple_product, name: 'Product 4') }
  let!(:v1) { p1.variants.first }
  let!(:v2) { p2.variants.first }
  let!(:v3) { p3.variants.first }
  let!(:v4) { p4.variants.first }
  let!(:d1)  { create(:distributor_enterprise) }
  let!(:d2)  { create(:distributor_enterprise) }
  let!(:oc1) { create(:simple_order_cycle, distributors: [d1], variants: [v1, v3]) }
  let!(:oc2) { create(:simple_order_cycle, distributors: [d1], variants: [v2]) }
  let!(:oc3) { create(:simple_order_cycle, distributors: [d2], variants: [v4]) }
  let!(:s1) { create(:schedule, order_cycles: [oc1]) }
  let!(:s2) { create(:schedule, order_cycles: [oc2]) }

  let(:scoper) { OpenFoodNetwork::ScopeVariantsForSearch.new(params) }

  describe "search" do
    let(:result) { scoper.search }

    context "when a search query is provided" do
      let(:params) { { q: "product 1" } }

      it "returns all products whose names or SKUs match the query" do
        expect(result).to include v1, v2
        expect(result).to_not include v3, v4
      end
    end

    context "when a schedule_id is specified" do
      let(:params) { { q: "product", schedule_id: s1.id } }

      it "returns all products distributed through that schedule" do
        lala = result
        expect(lala).to include v1, v3
        expect(result).to_not include v2, v4
      end
    end

    context "when an order_cycle_id is specified" do
      let(:params) { { q: "product", order_cycle_id: oc2.id } }

      it "returns all products distributed through that order cycle" do
        expect(result).to include v2
        expect(result).to_not include v1, v3, v4
      end
    end

    context "when a distributor_id is specified" do
      let(:params) { { q: "product", distributor_id: d2.id } }

      it "returns all products distributed through that distributor" do
        expect(result).to include v4
        expect(result).to_not include v1, v2, v3
      end
    end
  end
end
