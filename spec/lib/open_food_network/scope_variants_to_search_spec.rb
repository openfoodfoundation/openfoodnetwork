# frozen_string_literal: true

require 'spec_helper'
require 'open_food_network/scope_variants_for_search'
require 'spec_helper'

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

      context "matching both product SKUs and variant SKUs" do
        let!(:v5) { create(:variant, sku: "Product 1b") }

        it "returns all variants whose SKU or product's SKU match the query" do
          expect(result).to include v1, v2, v5
          expect(result).to_not include v3, v4
        end
      end
    end

    context "when a schedule_id is specified" do
      let(:params) { { q: "product", schedule_id: s1.id } }

      it "returns all products distributed through that schedule" do
        expect(result).to include v1, v3
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

      context "filtering by stock availability" do
        let!(:distributor1_variant_on_hand_but_not_backorderable) do
          create_variant_with_stock_item_for(d1, backorderable: false, count_on_hand: 1)
        end
        let!(:distributor1_variant_backorderable_but_not_on_hand) do
          create_variant_with_stock_item_for(d1, backorderable: true, count_on_hand: 0)
        end
        let!(:distributor1_variant_not_backorderable_and_not_on_hand) do
          create_variant_with_stock_item_for(d1, backorderable: false, count_on_hand: 0)
        end
        let!(:distributor1_variant_with_override_on_hand_but_not_on_demand) do
          create_variant_with_variant_override_for(d1, on_demand: false, count_on_hand: 1)
        end
        let!(:distributor1_variant_with_override_on_demand_but_not_on_hand) do
          create_variant_with_variant_override_for(d1, on_demand: true, count_on_hand: nil)
        end
        let!(:distributor1_variant_with_override_not_on_demand_and_not_on_hand) do
          create_variant_with_variant_override_for(d1, on_demand: false, count_on_hand: 0)
        end
        let!(:distributor1_variant_with_override_not_in_stock_but_producer_in_stock) do
          variant = create(:simple_product).variants.first
          variant.stock_items.first.update!(backorderable: false, count_on_hand: 1)
          create(:simple_order_cycle, distributors: [d1], variants: [variant])
          create(:variant_override, variant: variant, hub: d1, on_demand: false, count_on_hand: 0)
          variant
        end
        let!(:distributor1_variant_with_override_without_stock_level_set_and_no_producer_stock) do
          variant = create(:simple_product).variants.first
          variant.stock_items.first.update!(backorderable: false, count_on_hand: 0)
          create(:simple_order_cycle, distributors: [d1], variants: [variant])
          create(:variant_override, variant: variant, hub: d1, on_demand: nil, count_on_hand: nil)
          variant
        end
        let!(:distributor1_variant_with_override_without_stock_level_set_but_producer_in_stock) do
          variant = create(:simple_product).variants.first
          variant.stock_items.first.update!(backorderable: false, count_on_hand: 1)
          create(:simple_order_cycle, distributors: [d1], variants: [variant])
          create(:variant_override, variant: variant, hub: d1, on_demand: nil, count_on_hand: nil)
          variant
        end
        let!(:distributor2_variant_with_override_in_stock) do
          create_variant_with_variant_override_for(d2, on_demand: true, count_on_hand: nil)
        end

        context "when :include_out_of_stock is not specified" do
          let(:params) { { distributor_id: d1.id } }

          it "returns variants for the given distributor if they have a variant override which is
              in stock, or if they have a variant override with no stock level set but the producer
              has stock, or if they don't have a variant override and the producer has stock" do
            expect(result).to include(
              distributor1_variant_on_hand_but_not_backorderable,
              distributor1_variant_backorderable_but_not_on_hand,
              distributor1_variant_with_override_on_demand_but_not_on_hand,
              distributor1_variant_with_override_on_hand_but_not_on_demand,
              distributor1_variant_with_override_without_stock_level_set_but_producer_in_stock
            )
            expect(result).to_not include(
              distributor1_variant_not_backorderable_and_not_on_hand,
              distributor1_variant_with_override_not_on_demand_and_not_on_hand,
              distributor1_variant_with_override_not_in_stock_but_producer_in_stock,
              distributor1_variant_with_override_without_stock_level_set_and_no_producer_stock,
              distributor2_variant_with_override_in_stock
            )
          end
        end

        context "when :include_out_of_stock is specified" do
          let(:params) { { distributor_id: d1.id, include_out_of_stock: "1" } }

          it "returns all variants for the given distributor even if they are not in stock" do
            expect(result).to include(
              distributor1_variant_on_hand_but_not_backorderable,
              distributor1_variant_backorderable_but_not_on_hand,
              distributor1_variant_with_override_on_demand_but_not_on_hand,
              distributor1_variant_with_override_on_hand_but_not_on_demand,
              distributor1_variant_with_override_without_stock_level_set_but_producer_in_stock,
              distributor1_variant_with_override_without_stock_level_set_and_no_producer_stock,
              distributor1_variant_not_backorderable_and_not_on_hand,
              distributor1_variant_with_override_not_on_demand_and_not_on_hand,
              distributor1_variant_with_override_not_in_stock_but_producer_in_stock
            )
            expect(result).to_not include(
              distributor2_variant_with_override_in_stock
            )
          end
        end
      end
    end

    context "searching products starting with the same 3 caracters" do
      let(:params) { { q: "pro" } }
      it "returns variants ordered by display_name" do
        p1.name = "Product b"
        p2.name = "Product a"
        p3.name = "Product c"
        p4.name = "Product 1"
        p1.save!
        p2.save!
        p3.save!
        p4.save!
        expect(result.map(&:name)).
          to eq(["Product 1", "Product a", "Product b", "Product c"])
      end
    end
  end

  private

  def create_variant_with_stock_item_for(distributor, stock_item_attributes)
    variant = create(:simple_product).variants.first
    variant.stock_items.first.update!(stock_item_attributes)
    create(:simple_order_cycle, distributors: [distributor], variants: [variant])
    variant
  end

  def create_variant_with_variant_override_for(distributor, variant_override_attributes)
    variant = create(:simple_product).variants.first
    variant.stock_items.first.update!(backorderable: false, count_on_hand: 0)
    create(:simple_order_cycle, distributors: [distributor], variants: [variant])
    create(:variant_override, {
      variant: variant,
      hub: distributor
    }.merge(variant_override_attributes))
    variant
  end
end
