require 'spec_helper'

describe ProducerProperty do
  describe "products caching" do
    let(:producer) { create(:supplier_enterprise) }
    let(:pp) { producer.producer_properties.first }

    before do
      producer.set_producer_property 'Organic Certified', 'NASAA 54321'
    end

    it "refreshes the products cache on change" do
      expect(OpenFoodNetwork::ProductsCache).to receive(:producer_property_changed).with(pp)
      pp.value = 123
      pp.save
    end

    it "refreshes the products cache on destruction" do
      expect(OpenFoodNetwork::ProductsCache).to receive(:producer_property_destroyed).with(pp)
      pp.destroy
    end
  end
end
