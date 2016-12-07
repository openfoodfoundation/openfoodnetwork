require 'spec_helper'

describe ProducerProperty do
  let(:producer) { create(:supplier_enterprise) }
  let(:pp) { producer.producer_properties.first }

  before do
    producer.set_producer_property 'Organic Certified', 'NASAA 54321'
  end

  describe ".currently_sold_by and .ever_sold_by" do
    let!(:shop) { create(:distributor_enterprise) }
    let!(:oc) { create(:simple_order_cycle, distributors: [shop], variants: [product.variants.first]) }
    let(:product) { create(:simple_product, supplier: producer) }
    let(:producer_other) { create(:supplier_enterprise) }
    let(:product_other) { create(:simple_product, supplier: producer_other) }
    let(:pp_other) { producer_other.producer_properties.first }

    before do
      producer_other.set_producer_property 'Spiffy', 'Ya'
    end

    describe "with an associated producer property" do
      it "returns the producer property" do
        expect(ProducerProperty.currently_sold_by(shop)).to eq [pp]
        expect(ProducerProperty.ever_sold_by(shop)).to eq [pp]
      end
    end

    describe "with a producer property for a producer not carried by that shop" do
      let!(:exchange) { create(:exchange, order_cycle: oc, incoming: true, sender: producer_other, receiver: oc.coordinator) }

      it "doesn't return the producer property" do
        expect(ProducerProperty.currently_sold_by(shop)).not_to include pp_other
        expect(ProducerProperty.ever_sold_by(shop)).not_to include pp_other
      end
    end

    describe "with a producer property for a product in a different shop" do
      let(:shop_other) { create(:distributor_enterprise) }
      let!(:oc) { create(:simple_order_cycle, distributors: [shop], variants: [product.variants.first]) }
      let!(:exchange) { create(:exchange, order_cycle: oc, incoming: false, sender: oc.coordinator, receiver: shop_other, variants: [product_other.variants.first]) }

      it "doesn't return the producer property" do
        expect(ProducerProperty.currently_sold_by(shop)).not_to include pp_other
        expect(ProducerProperty.ever_sold_by(shop)).not_to include pp_other
      end
    end

    describe "with a producer property for a product in a closed order cycle" do
      before do
        oc.update_attributes! orders_close_at: 1.week.ago
      end

      it "doesn't return the producer property for .currently_sold_by" do
        expect(ProducerProperty.currently_sold_by(shop)).not_to include pp
      end

      it "returns the producer property for .ever_sold_by" do
        expect(ProducerProperty.ever_sold_by(shop)).to include pp
      end
    end

    describe "with a duplicate producer property" do
      let(:product2) { create(:simple_product, supplier: producer) }
      let!(:oc) { create(:simple_order_cycle, distributors: [shop], variants: [product.variants.first, product2.variants.first]) }

      it "doesn't return duplicates" do
        expect(ProducerProperty.currently_sold_by(shop).to_a.count).to eq 1
        expect(ProducerProperty.ever_sold_by(shop).to_a.count).to eq 1
      end
    end
  end

  describe "products caching" do
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
