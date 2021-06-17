# frozen_string_literal: true

require "spec_helper"

describe Api::Admin::ForOrderCycle::SuppliedProductSerializer do
  let(:coordinator)         { create(:distributor_enterprise) }
  let(:order_cycle)         { double(:order_cycle, coordinator: coordinator) }
  let!(:product) { create(:simple_product) }
  let!(:non_inventory_variant) { product.variants.first }
  let!(:inventory_variant) { create(:variant, product: product.reload) }
  let(:serialized_product) {
    Api::Admin::ForOrderCycle::SuppliedProductSerializer.new(product,
                                                             order_cycle: order_cycle ).to_json
  }
  let!(:inventory_item) {
    create(:inventory_item, enterprise: coordinator, variant: inventory_variant, visible: true)
  }

  context "when order cycle shows only variants in the coordinator's inventory" do
    before do
      allow(order_cycle).to receive(:prefers_product_selection_from_coordinator_inventory_only?) {
                              true
                            }
    end

    describe "variants" do
      it "renders only variants that are in the coordinators inventory" do
        expect(serialized_product).to have_json_size(1).at_path 'variants'
        expect(serialized_product).to be_json_eql(inventory_variant.id).at_path 'variants/0/id'
      end
    end
  end

  context "when order cycle shows all available products" do
    before do
      allow(order_cycle).to receive(:prefers_product_selection_from_coordinator_inventory_only?) {
                              false
                            }
    end

    describe "supplied products" do
      it "renders variants regardless of whether they are in the coordinators inventory" do
        expect(serialized_product).to have_json_size(2).at_path 'variants'
        variant_ids = parse_json(serialized_product)['variants'].map{ |v| v['id'] }
        expect(variant_ids).to include non_inventory_variant.id, inventory_variant.id
      end
    end
  end
end
