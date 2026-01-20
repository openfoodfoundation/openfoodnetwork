# frozen_string_literal: true

RSpec.describe OrderCycles::DistributedProductsService do
  # NOTE: product_relation_incl_supplier is tested via ProductsRenderer specs:
  # spec/services/products_renderer_spec.rb

  describe "#products_relation" do
    subject(:products_relation) {
      described_class.new(distributor, order_cycle, customer).products_relation
    }

    let(:distributor) { create(:distributor_enterprise) }
    let(:product) { create(:product) }
    let(:variant) { product.variants.first }
    let(:customer) { create(:customer) }
    let(:order_cycle) do
      create(:simple_order_cycle, distributors: [distributor], variants: [variant])
    end

    it "returns de duplicated result" do
      supplier = create(:supplier_enterprise)
      variant.update(supplier: )
      create(:variant, product:, supplier: )
      expect(products_relation).to eq([product])
    end

    describe "product distributed by distributor in the OC" do
      it "returns products" do
        expect(products_relation).to eq([product])
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
        expect(products_relation).not_to include product
      end
    end

    describe "product distributed by another distributor in the OC" do
      let(:another_distributor) { create(:distributor_enterprise) }
      let(:order_cycle) do
        create(:simple_order_cycle, distributors: [another_distributor], variants: [variant])
      end

      it "does not return product" do
        expect(products_relation).not_to include product
      end
    end

    describe "filtering products that are out of stock" do
      context "with regular variants" do
        it "returns product when variant is in stock" do
          expect(products_relation).to include product
        end

        it "does not return product when variant is out of stock" do
          variant.update_attribute(:on_hand, 0)

          expect(products_relation).not_to include product
        end

        context "with variant_tag enabled" do
          subject(:products_relation) {
            described_class.new(
              distributor, order_cycle, customer, variant_tag_enabled: true
            ).products_relation
          }

          it "calls VariantTagRulesFilterer" do
            expect(VariantTagRulesFilterer).to receive(:new).and_call_original

            products_relation
          end
        end
      end

      context "with variant overrides" do
        subject(:products_relation) {
          described_class.new(
            distributor, order_cycle, customer, inventory_enabled: true
          ).products_relation
        }

        let!(:override) {
          create(:variant_override, hub: distributor, variant:, count_on_hand: 0)
        }

        it "calls ProductTagRulesFilterer" do
          expect(ProductTagRulesFilterer).to receive(:new).and_call_original

          products_relation
        end

        it "does not return product when an override is out of stock" do
          expect(products_relation).not_to include product
        end

        it "returns product when an override is in stock" do
          variant.update_attribute(:on_hand, 0)
          override.update_attribute(:count_on_hand, 10)

          expect(products_relation).to include product
        end
      end
    end

    describe "sorting" do
      let(:order_cycle) do
        create(:simple_order_cycle, distributors: [distributor])
      end
      let(:exchange) { order_cycle.exchanges.to_enterprises(distributor).outgoing.first }

      let(:fruits) { create(:taxon) }
      let(:cakes) { create(:taxon) }
      let(:fruits_supplier) { create(:supplier_enterprise) }
      let(:cakes_supplier) { create(:supplier_enterprise) }
      let!(:product_apples) {
        create(:product, name: "apples", primary_taxon_id: fruits.id,
                         supplier_id: fruits_supplier.id, inherits_properties: true)
      }
      let!(:product_banana_bread) {
        create(:product, name: "banana bread", primary_taxon_id: cakes.id,
                         supplier_id: cakes_supplier.id, inherits_properties: true)
      }
      let!(:product_cherries) {
        create(:product, name: "cherries", primary_taxon_id: fruits.id,
                         supplier_id: fruits_supplier.id, inherits_properties: true)
      }
      let!(:product_doughnuts) {
        create(:product, name: "doughnuts", primary_taxon_id: cakes.id,
                         supplier_id: cakes_supplier.id, inherits_properties: true)
      }

      before do
        exchange.variants << product_apples.variants.first
        exchange.variants << product_banana_bread.variants.first
        exchange.variants << product_cherries.variants.first
        exchange.variants << product_doughnuts.variants.first
      end

      it "sorts products by the distributor's preferred taxon list" do
        allow(distributor)
          .to receive(:preferred_shopfront_product_sorting_method) { "by_category" }
        allow(distributor)
          .to receive(:preferred_shopfront_taxon_order) { "#{cakes.id},#{fruits.id}" }

        expect(products_relation)
          .to eq([product_banana_bread, product_doughnuts, product_apples, product_cherries])
      end

      it "sorts products by the distributor's preferred producer list" do
        allow(distributor)
          .to receive(:preferred_shopfront_product_sorting_method) { "by_producer" }
        allow(distributor).to receive(:preferred_shopfront_producer_order) {
          "#{cakes_supplier.id},#{fruits_supplier.id}"
        }

        expect(products_relation)
          .to eq([product_banana_bread, product_doughnuts, product_apples, product_cherries])
      end

      it "alphabetizes products by name when taxon list is not set" do
        allow(distributor).to receive(:preferred_shopfront_taxon_order) { "" }

        expect(products_relation)
          .to eq([product_apples, product_banana_bread, product_cherries, product_doughnuts])
      end
    end
  end

  describe "#variants_relation" do
    let(:distributor) { create(:distributor_enterprise) }
    let(:oc) { create(:simple_order_cycle, distributors: [distributor], variants: [v1, v3]) }
    let(:customer) { create(:customer) }
    let(:product) { create(:simple_product) }
    let!(:v1) { create(:variant, product:) }
    let!(:v2) { create(:variant, product:) }
    let!(:v3) { create(:variant, product:) }
    let!(:vo) { create(:variant_override, hub: distributor, variant_id: v3.id, count_on_hand: 0) }
    let(:variants) {
      described_class.new(distributor, oc, customer, inventory_enabled: true).variants_relation
    }

    it "returns variants in the oc" do
      expect(variants).to include v1
      expect(variants).not_to include v2
    end

    it "does not return variants where override is out of stock" do
      expect(variants).not_to include v3
    end
  end
end
