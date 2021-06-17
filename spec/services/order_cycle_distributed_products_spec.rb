# frozen_string_literal: true

require 'spec_helper'

describe OrderCycleDistributedProducts do
  describe "#products_relation" do
    let(:distributor) { create(:distributor_enterprise) }
    let(:product) { create(:product) }
    let(:variant) { product.variants.first }
    let(:customer) { create(:customer) }
    let(:order_cycle) do
      create(:simple_order_cycle, distributors: [distributor], variants: [variant])
    end

    describe "product distributed by distributor in the OC" do
      it "returns products" do
        expect(described_class.new(distributor, order_cycle,
                                   customer).products_relation).to eq([product])
      end
    end

    describe "product distributed by distributor in another OC" do
      let(:reference_variant) { create(:product).variants.first }
      let(:order_cycle) do
        create(:simple_order_cycle, distributors: [distributor], variants: [reference_variant])
      end
      let(:another_order_cycle) do
        create(:simple_order_cycle, distributors: [distributor], variants: [variant])
      end

      it "does not return product" do
        expect(described_class.new(distributor, order_cycle,
                                   customer).products_relation).to_not include product
      end
    end

    describe "product distributed by another distributor in the OC" do
      let(:another_distributor) { create(:distributor_enterprise) }
      let(:order_cycle) do
        create(:simple_order_cycle, distributors: [another_distributor], variants: [variant])
      end

      it "does not return product" do
        expect(described_class.new(distributor, order_cycle,
                                   customer).products_relation).to_not include product
      end
    end

    describe "filtering products that are out of stock" do
      context "with regular variants" do
        it "returns product when variant is in stock" do
          expect(described_class.new(distributor, order_cycle,
                                     customer).products_relation).to include product
        end

        it "does not return product when variant is out of stock" do
          variant.update_attribute(:on_hand, 0)
          expect(described_class.new(distributor, order_cycle,
                                     customer).products_relation).to_not include product
        end
      end

      context "with variant overrides" do
        let!(:override) {
          create(:variant_override, hub: distributor, variant: variant, count_on_hand: 0)
        }

        it "does not return product when an override is out of stock" do
          expect(described_class.new(distributor, order_cycle,
                                     customer).products_relation).to_not include product
        end

        it "returns product when an override is in stock" do
          variant.update_attribute(:on_hand, 0)
          override.update_attribute(:count_on_hand, 10)
          expect(described_class.new(distributor, order_cycle,
                                     customer).products_relation).to include product
        end
      end
    end
  end

  describe "#variants_relation" do
    let(:distributor) { create(:distributor_enterprise) }
    let(:oc) { create(:simple_order_cycle, distributors: [distributor], variants: [v1, v3]) }
    let(:customer) { create(:customer) }
    let(:product) { create(:simple_product) }
    let!(:v1) { create(:variant, product: product) }
    let!(:v2) { create(:variant, product: product) }
    let!(:v3) { create(:variant, product: product) }
    let!(:vo) { create(:variant_override, hub: distributor, variant_id: v3.id, count_on_hand: 0) }
    let(:variants) { described_class.new(distributor, oc, customer).variants_relation }

    it "returns variants in the oc" do
      expect(variants).to include v1
      expect(variants).to_not include v2
    end

    it "does not return variants where override is out of stock" do
      expect(variants).to_not include v3
    end
  end
end
